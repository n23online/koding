// ctifactories implements abstractions ontop of the CLI commands, interfacting the
// CLI library of choice with the klientctl Commands created.
//
// TODO: Move this to it's own package, once the rest of the klientctl lib is
// package-able.
package main

import (
	"fmt"
	"koding/klientctl/util/mountcli"
	"os"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// MountCommandFactory creates a mount.Command instance and runs it with
// Stdin and Out.
func MountCommandFactory(c *cli.Context, log logging.Logger, cmdName string) Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	opts := MountOptions{
		Name:             c.Args().Get(0),
		LocalPath:        c.Args().Get(1),
		RemotePath:       c.String("remotepath"),     // note the lowercase of all chars
		NoIgnore:         c.Bool("noignore"),         // note the lowercase of all chars
		NoPrefetchMeta:   c.Bool("noprefetch-meta"),  // note the lowercase of all chars
		NoWatch:          c.Bool("nowatch"),          // note the lowercase of all chars
		PrefetchAll:      c.Bool("prefetch-all"),     // note the lowercase of all chars
		PrefetchInterval: c.Int("prefetch-interval"), // note the lowercase of all chars
		// Used for prefetch
		SSHDefaultKeyDir:  SSHDefaultKeyDir,
		SSHDefaultKeyName: SSHDefaultKeyName,
	}

	return &MountCommand{
		Options:       opts,
		Stdout:        os.Stdout,
		Stdin:         os.Stdin,
		Log:           log,
		KlientOptions: NewKlientOptions(),
		helper:        CommandHelper(c, "mount"),
		mountLocker:   Lock,
		homeDirGetter: homeDirGetter,
	}
}

// MountCommandFactory creates a mount.Command instance and runs it with
// Stdin and Out.
func UnmountCommandFactory(c *cli.Context, log logging.Logger, cmdName string) Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	// Full our unmount options from the CLI. Any empty options are okay, as
	// the command struct is responsible for verifying valid opts.
	opts := UnmountOptions{
		MountName: c.Args().First(),
	}

	return &UnmountCommand{
		Options:       opts,
		Stdout:        os.Stdout,
		Stdin:         os.Stdin,
		Log:           log,
		KlientOptions: NewKlientOptions(),
		helper:        CommandHelper(c, cmdName),
		healthChecker: defaultHealthChecker,
		fileRemover:   os.Remove,
		mountFinder:   mountcli.NewMount(),
	}
}