package main

import (
	"errors"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
)

var (
	inputISO     string
	outputImage  string
	workDir      string
	workDirSet   bool
	isoMount     string
	isoRoot      string
	chrootDir    string
	cleanupTasks []func()
)

func logInfo(msg string) {
	log.Printf("[INFO] %s", msg)
}

func logFatal(msg string) {
	log.Fatalf("[ERROR] %s", msg)
}

func runCommand(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stderr = os.Stderr
	cmd.Stdout = os.Stdout
	logInfo(fmt.Sprintf("Running: %s %s", name, strings.Join(args, " ")))
	if err := cmd.Run(); err != nil {
		logFatal(fmt.Sprintf("Command failed: %s %v", name, err))
	}
}

func ensureDir(path string) {
	if _, err := os.Stat(path); os.IsNotExist(err) {
		if err := os.MkdirAll(path, 0755); err != nil {
			logFatal(fmt.Sprintf("Failed to create directory: %s", path))
		}
	}
}

func isRoot() bool {
	return os.Geteuid() == 0
}

func cleanup() {
	logInfo("Running cleanup...")
	for _, task := range cleanupTasks {
		task()
	}
	logInfo("Cleanup complete.")
}

func addCleanup(task func()) {
	cleanupTasks = append([]func(){task}, cleanupTasks...)
}

func mustAbs(path string) string {
	abs, err := filepath.Abs(path)
	if err != nil {
		logFatal(fmt.Sprintf("Failed to resolve absolute path: %s", err))
	}
	return abs
}

func parseArgs() {
	flag.StringVar(&inputISO, "i", "", "Input ISO path (required)")
	flag.StringVar(&inputISO, "input", "", "Input ISO path (required)")
	flag.StringVar(&outputImage, "o", "", "Output image path (.img)")
	flag.StringVar(&outputImage, "output", "", "Output image path (.img)")
	flag.StringVar(&workDir, "w", "", "Working directory")
	flag.StringVar(&workDir, "workdir", "", "Working directory")
	flag.Parse()

	if inputISO == "" {
		logFatal("Input ISO is required")
	}

	inputISO = mustAbs(inputISO)
	if _, err := os.Stat(inputISO); err != nil {
		logFatal(fmt.Sprintf("Input ISO not found: %s", inputISO))
	}

	if outputImage == "" {
		base := filepath.Base(inputISO)
		name := strings.TrimSuffix(base, filepath.Ext(base))
		outputImage = mustAbs(name + "-custom.img")
	} else {
		outputImage = mustAbs(outputImage)
	}

	if !strings.HasSuffix(outputImage, ".img") {
		logFatal("Output image must end in .img")
	}

	if workDir == "" {
		tmp := filepath.Join(os.TempDir(), fmt.Sprintf("sudobuild-%d", os.Getpid()))
		workDir = mustAbs(tmp)
		workDirSet = false
	} else {
		workDir = mustAbs(workDir)
		workDirSet = true
	}
}

func main() {
	if !isRoot() {
		logFatal("This program must be run as root.")
	}

	parseArgs()
	defer cleanup()

	isoMount = filepath.Join(workDir, "iso-mount")
	isoRoot = filepath.Join(workDir, "iso-root")
	chrootDir = filepath.Join(workDir, "chroot")

	ensureDir(isoMount)
	ensureDir(isoRoot)
	ensureDir(chrootDir)

	addCleanup(func() {
		runCommand("umount", "-lf", isoMount)
	})

	if !workDirSet {
		addCleanup(func() {
			logInfo("Removing temporary workdir: " + workDir)
			_ = os.RemoveAll(workDir)
		})
	}

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)
	go func() {
		<-sigs
		os.Exit(1)
	}()

	logInfo("Input ISO: " + inputISO)
	logInfo("Output: " + outputImage)
	logInfo("Workdir: " + workDir)

	logInfo("Mounting ISO...")
	runCommand("mount", "-o", "loop", inputISO, isoMount)

	logInfo("Copying ISO contents...")
	runCommand("cp", "-a", isoMount+"/.", isoRoot)

	logInfo("Preparing chroot patching (placeholder)...")
	//  unsquashfs + patch logic here

	logInfo("Writing final image (placeholder): " + outputImage)
	//  xorriso/genisoimage logic here

	logInfo("Completed successfully.")
}
