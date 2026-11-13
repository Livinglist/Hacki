package proxy

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"time"

	_ "modernc.org/sqlite"
)

type cachedResponse struct {
	status   int
	header   http.Header
	body     []byte
	storedAt time.Time
}

// Cache persists successful public responses, including expired entries so they
// remain available when Hacker News itself is rate limited.
type Cache struct {
	db *sql.DB
}

func OpenCache(path string) (*Cache, error) {
	if path == "" {
		return nil, errors.New("cache path must not be empty")
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return nil, fmt.Errorf("create cache directory: %w", err)
	}
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return nil, fmt.Errorf("create cache file: %w", err)
	}
	if err := file.Close(); err != nil {
		return nil, err
	}
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, err
	}
	// A single connection makes the connection-scoped pragmas consistent and
	// serializes small cache writes without SQLite writer lock contention.
	db.SetMaxOpenConns(1)
	_, err = db.Exec(`PRAGMA journal_mode = WAL;
PRAGMA busy_timeout = 5000;
CREATE TABLE IF NOT EXISTS responses (
    cache_key TEXT PRIMARY KEY,
    status INTEGER NOT NULL,
    headers BLOB NOT NULL,
    body BLOB NOT NULL,
    stored_at INTEGER NOT NULL
);`)
	if err != nil {
		db.Close()
		return nil, fmt.Errorf("initialize cache: %w", err)
	}
	return &Cache{db: db}, nil
}

func (c *Cache) Close() error { return c.db.Close() }

func (c *Cache) get(ctx context.Context, key string) (*cachedResponse, error) {
	var response cachedResponse
	var headers []byte
	var storedAt int64
	err := c.db.QueryRowContext(ctx,
		`SELECT status, headers, body, stored_at FROM responses WHERE cache_key = ?`,
		key,
	).Scan(&response.status, &headers, &response.body, &storedAt)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	if err := json.Unmarshal(headers, &response.header); err != nil {
		return nil, err
	}
	response.storedAt = time.UnixMilli(storedAt)
	return &response, nil
}

func (c *Cache) put(ctx context.Context, key string, response *cachedResponse) error {
	headers, err := json.Marshal(response.header)
	if err != nil {
		return err
	}
	_, err = c.db.ExecContext(ctx, `INSERT INTO responses
    (cache_key, status, headers, body, stored_at) VALUES (?, ?, ?, ?, ?)
ON CONFLICT(cache_key) DO UPDATE SET status = excluded.status,
    headers = excluded.headers, body = excluded.body, stored_at = excluded.stored_at`,
		key, response.status, headers, response.body, response.storedAt.UnixMilli())
	return err
}
