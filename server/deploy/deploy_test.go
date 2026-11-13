package deploy

import (
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

const (
	oldImage  = "sha256:old-image"
	newImage  = "sha256:new-image"
	commit    = "1111111111111111111111111111111111111111"
	oldConfig = "services:\n  hacki-server:\n    image: ${HACKI_IMAGE}\n    environment:\n      CONFIG_VERSION: previous\n"
	newConfig = "services:\n  hacki-server:\n    image: ${HACKI_IMAGE}\n    environment:\n      CONFIG_VERSION: incoming\n"
)

type runtimeState struct {
	Image   string
	Config  string
	Running bool
}

type commandEvent struct {
	Command string
	Image   string
	Config  string
}

// Run the real deployment script, replacing only Docker, HTTP, and delay
// commands. The fake runtime rejects an invalid command for either image, just
// as Docker would: selecting an older image cannot repair a broken Compose file.
func TestRollbackRestoresWorkingComposeConfiguration(t *testing.T) {
	broken := newConfig + "    command: /missing-executable\n"
	h := newHarness(t, broken)
	if output, err := h.run(false); err == nil {
		t.Fatalf("broken configuration unexpectedly deployed:\n%s", output)
	}
	h.assertRuntime(oldImage, oldConfig)
	h.assertFile("compose.production.yaml", oldConfig)
	h.assertFile(".deployed-image", oldImage+"\n")
	if !h.hasEvent("up", oldImage, oldConfig) || !h.hasEvent("health", oldImage, oldConfig) {
		t.Fatal("rollback must start and health-check the previous configuration")
	}
}

func TestRollbackHealthCheckUsesPreviousConfiguration(t *testing.T) {
	h := newHarness(t, newConfig)
	if output, err := h.run(true); err == nil {
		t.Fatalf("unhealthy image unexpectedly deployed:\n%s", output)
	}
	h.assertRuntime(oldImage, oldConfig)
	h.assertFile("compose.production.yaml", oldConfig)
	if !h.hasEvent("ps", newImage, newConfig) || !h.hasEvent("ps", oldImage, oldConfig) ||
		!h.hasEvent("health", newImage, newConfig) || !h.hasEvent("health", oldImage, oldConfig) {
		t.Fatal("expected checks of the candidate and restored service configurations")
	}
}

func TestSuccessfulDeploymentSavesNewConfiguration(t *testing.T) {
	h := newHarness(t, newConfig)
	if output, err := h.run(false); err != nil {
		t.Fatalf("deployment failed: %v\n%s", err, output)
	}
	h.assertRuntime(newImage, newConfig)
	h.assertFile("compose.production.yaml", newConfig)
	h.assertFile(".deployed-image", newImage+"\n")
}

func TestExistingServiceWithoutSavedConfigurationIsUntouched(t *testing.T) {
	h := newHarness(t, newConfig)
	if err := os.Remove(filepath.Join(h.root, "compose.production.yaml")); err != nil {
		t.Fatal(err)
	}
	if output, err := h.run(false); err == nil {
		t.Fatalf("replaced a service with no recoverable configuration:\n%s", output)
	}
	h.assertRuntime(oldImage, oldConfig)
	h.assertFile(".deployed-image", oldImage+"\n")
	for _, event := range h.events() {
		if event.Command == "load" || event.Command == "up" || event.Command == "stop" {
			t.Fatalf("service was modified before rollback prerequisites were satisfied: %+v", event)
		}
	}
}

func TestFirstDeploymentWithoutSavedConfigurationSucceeds(t *testing.T) {
	h := newHarness(t, newConfig)
	if err := os.Remove(filepath.Join(h.root, "compose.production.yaml")); err != nil {
		t.Fatal(err)
	}
	h.write("state.json", `{"Image":"","Config":"","Running":false}`)
	if output, err := h.run(false); err != nil {
		t.Fatalf("initial deployment failed: %v\n%s", err, output)
	}
	h.assertRuntime(newImage, newConfig)
	h.assertFile("compose.production.yaml", newConfig)
	h.assertFile(".deployed-image", newImage+"\n")
}

type harness struct {
	t      *testing.T
	root   string
	bundle string
	bin    string
}

func newHarness(t *testing.T, incoming string) *harness {
	t.Helper()
	for _, command := range []string{"bash", "gzip", "flock"} {
		if _, err := exec.LookPath(command); err != nil {
			t.Skipf("Linux deployment dependency %s unavailable", command)
		}
	}
	h := &harness{t: t, root: t.TempDir()}
	h.bundle = filepath.Join(h.root, ".incoming-1-1")
	h.bin = filepath.Join(h.root, "bin")
	for _, dir := range []string{h.bundle, h.bin} {
		if err := os.Mkdir(dir, 0o700); err != nil {
			t.Fatal(err)
		}
	}
	h.write(".env", "HACKI_API_KEY=test-only-key\nHACKI_CACHE_TTL=30m\n")
	h.write("compose.production.yaml", oldConfig)
	h.write(".deployed-image", oldImage+"\n")
	h.write(".incoming-1-1/compose.production.yaml", incoming)
	state, _ := json.Marshal(runtimeState{oldImage, oldConfig, true})
	h.write("state.json", string(state))
	archive, err := os.Create(filepath.Join(h.bundle, "image.tar.gz"))
	if err != nil {
		t.Fatal(err)
	}
	compressed := gzip.NewWriter(archive)
	if _, err := compressed.Write([]byte("saved test image")); err != nil {
		t.Fatal(err)
	}
	if err := compressed.Close(); err != nil {
		t.Fatal(err)
	}
	if err := archive.Close(); err != nil {
		t.Fatal(err)
	}
	for _, command := range []string{"docker", "curl"} {
		script := fmt.Sprintf("#!/bin/sh\nexec \"$HACKI_DEPLOY_TEST_BINARY\" -test.run=^TestDeployCommandHelper$ -- %s \"$@\"\n", command)
		if err := os.WriteFile(filepath.Join(h.bin, command), []byte(script), 0o700); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(h.bin, "sleep"), []byte("#!/bin/sh\nexit 0\n"), 0o700); err != nil {
		t.Fatal(err)
	}
	return h
}

func (h *harness) write(path, value string) {
	h.t.Helper()
	if err := os.WriteFile(filepath.Join(h.root, path), []byte(value), 0o600); err != nil {
		h.t.Fatal(err)
	}
}

func (h *harness) run(failHealth bool) ([]byte, error) {
	h.t.Helper()
	binary, err := os.Executable()
	if err != nil {
		h.t.Fatal(err)
	}
	command := exec.Command("bash", "deploy.sh", h.root, commit, h.bundle)
	command.Env = append(os.Environ(),
		"PATH="+h.bin+string(os.PathListSeparator)+os.Getenv("PATH"),
		"HACKI_DEPLOY_TEST_BINARY="+binary,
		"HACKI_DEPLOY_COMMAND_HELPER=1",
		"HACKI_DEPLOY_TEST_ROOT="+h.root,
		fmt.Sprintf("HACKI_DEPLOY_FAIL_HEALTH=%t", failHealth),
		"GORACE=atexit_sleep_ms=0",
	)
	return command.CombinedOutput()
}

func (h *harness) assertFile(path, expected string) {
	h.t.Helper()
	actual, err := os.ReadFile(filepath.Join(h.root, path))
	if err != nil || string(actual) != expected {
		h.t.Fatalf("%s = %q, %v; want %q", path, actual, err, expected)
	}
}

func (h *harness) assertRuntime(image, config string) {
	h.t.Helper()
	var state runtimeState
	data, err := os.ReadFile(filepath.Join(h.root, "state.json"))
	if err != nil {
		h.t.Fatal(err)
	}
	if err := json.Unmarshal(data, &state); err != nil {
		h.t.Fatal(err)
	}
	if !state.Running || state.Image != image || state.Config != config {
		h.t.Fatalf("runtime = %+v; want running %s with %q", state, image, config)
	}
}

func (h *harness) events() []commandEvent {
	h.t.Helper()
	data, err := os.ReadFile(filepath.Join(h.root, "events.jsonl"))
	if err != nil {
		h.t.Fatal(err)
	}
	var events []commandEvent
	for _, line := range strings.Split(strings.TrimSpace(string(data)), "\n") {
		var event commandEvent
		if err := json.Unmarshal([]byte(line), &event); err != nil {
			h.t.Fatal(err)
		}
		events = append(events, event)
	}
	return events
}

func (h *harness) hasEvent(command, image, config string) bool {
	h.t.Helper()
	for _, event := range h.events() {
		if event.Command == command && event.Image == image && event.Config == config {
			return true
		}
	}
	return false
}

// TestDeployCommandHelper is a subprocess entry point, not a deployment model:
// it provides the observable behavior of the external Docker and HTTP commands.
func TestDeployCommandHelper(t *testing.T) {
	if os.Getenv("HACKI_DEPLOY_COMMAND_HELPER") != "1" {
		return
	}
	args := os.Args
	for len(args) > 0 && args[0] != "--" {
		args = args[1:]
	}
	if len(args) < 2 {
		os.Exit(2)
	}
	code, err := fakeCommand(args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	os.Exit(code)
}

func fakeCommand(args []string) (int, error) {
	root := os.Getenv("HACKI_DEPLOY_TEST_ROOT")
	data, err := os.ReadFile(filepath.Join(root, "state.json"))
	if err != nil {
		return 0, err
	}
	var state runtimeState
	if err := json.Unmarshal(data, &state); err != nil {
		return 0, err
	}
	image, config, command := os.Getenv("HACKI_IMAGE"), "", ""
	if args[0] == "curl" {
		command, image, config = "health", state.Image, state.Config
	} else if len(args) > 1 && args[1] == "compose" {
		for i := 2; i < len(args); i++ {
			switch args[i] {
			case "--file", "-f":
				i++
				data, err := os.ReadFile(args[i])
				if err != nil {
					return 0, err
				}
				config = string(data)
			case "ps", "up", "stop":
				command = args[i]
			}
		}
	} else if len(args) > 1 && args[1] == "load" {
		command = "load"
		if _, err := io.Copy(io.Discard, os.Stdin); err != nil {
			return 0, err
		}
	} else if len(args) > 1 && args[1] == "image" {
		fmt.Println(newImage)
		return 0, nil
	} else if len(args) > 3 && args[1] == "inspect" {
		switch args[3] {
		case "{{.Image}}":
			fmt.Println(state.Image)
		case "{{.State.Running}}":
			fmt.Println(state.Running)
		default:
			return 0, fmt.Errorf("unsupported inspect format: %v", args)
		}
		return 0, nil
	}
	log, err := os.OpenFile(filepath.Join(root, "events.jsonl"), os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		return 0, err
	}
	err = json.NewEncoder(log).Encode(commandEvent{command, image, config})
	if closeErr := log.Close(); err == nil {
		err = closeErr
	}
	if err != nil {
		return 0, err
	}
	switch command {
	case "ps":
		if state.Image != "" && (state.Running || strings.Contains(strings.Join(args, " "), "-aq")) {
			fmt.Println("service-container")
		}
	case "up":
		if image != oldImage {
			image = newImage
		}
		state = runtimeState{image, config, !strings.Contains(config, "command: /missing-executable")}
		data, err := json.Marshal(state)
		if err != nil {
			return 0, err
		}
		if err := os.WriteFile(filepath.Join(root, "state.json"), data, 0o600); err != nil {
			return 0, err
		}
		if !state.Running {
			return 1, nil
		}
	case "health":
		if !state.Running || (state.Image == newImage && os.Getenv("HACKI_DEPLOY_FAIL_HEALTH") == "true") {
			return 1, nil
		}
	case "load":
	case "stop":
	default:
		return 0, fmt.Errorf("unsupported command: %v", args)
	}
	return 0, nil
}
