package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Livinglist/Hacki/server/internal/proxy"
)

func main() {
	if err := run(); err != nil {
		slog.Error("server stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	ttl, err := time.ParseDuration(env("HACKI_CACHE_TTL", "30m"))
	if err != nil || ttl <= 0 {
		return errors.New("HACKI_CACHE_TTL must be a positive Go duration (for example 30m)")
	}
	if os.Getenv("HACKI_API_KEY") == "" {
		return errors.New("HACKI_API_KEY is required")
	}
	cache, err := proxy.OpenCache(env("HACKI_CACHE_PATH", "data/cache.sqlite"))
	if err != nil {
		return fmt.Errorf("open cache: %w", err)
	}
	defer cache.Close()
	handler, err := proxy.NewHandler(proxy.Config{APIKey: os.Getenv("HACKI_API_KEY"), TTL: ttl}, cache)
	if err != nil {
		return err
	}
	server := &http.Server{
		Addr: env("HACKI_LISTEN_ADDR", "127.0.0.1:8080"), Handler: handler,
		ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 15 * time.Second,
		WriteTimeout: 40 * time.Second, IdleTimeout: 60 * time.Second,
		MaxHeaderBytes: 32 << 10,
	}
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	stopped := make(chan struct{})
	go func() {
		defer close(stopped)
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := server.Shutdown(shutdownCtx); err != nil {
			slog.Warn("graceful shutdown timed out")
			server.Close()
		}
	}()
	slog.Info("Hacki proxy listening", "address", server.Addr)
	err = server.ListenAndServe()
	stop()
	<-stopped
	if errors.Is(err, http.ErrServerClosed) {
		return nil
	}
	return err
}

func env(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
