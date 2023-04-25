package main

import (
	"flag"
	"fmt"
	"net"
	"net/http"
	"os"
	"os/exec"

	"github.com/labstack/echo/middleware"

	"github.com/labstack/echo"
	"github.com/sirupsen/logrus"
)

var logger = logrus.New()

func main() {
	var socketPath string
	flag.StringVar(&socketPath, "socket", "/run/guest-services/backend.sock", "Unix domain socket to listen on")
	flag.Parse()

	_ = os.RemoveAll(socketPath)

	logger.SetOutput(os.Stdout)

	logMiddleware := middleware.LoggerWithConfig(middleware.LoggerConfig{
		Skipper: middleware.DefaultSkipper,
		Format: `{"time":"${time_rfc3339_nano}","id":"${id}",` +
			`"method":"${method}","uri":"${uri}",` +
			`"status":${status},"error":"${error}"` +
			`}` + "\n",
		CustomTimeFormat: "2006-01-02 15:04:05.00000",
		Output:           logger.Writer(),
	})

	logger.Infof("Starting listening on %s\n", socketPath)
	router := echo.New()
	router.HideBanner = true
	router.Use(logMiddleware)
	startURL := ""

	ln, err := listen(socketPath)
	if err != nil {
		logger.Fatal(err)
	}
	router.Listener = ln

	router.GET("/init", initCommand)

	logger.Fatal(router.Start(startURL))
}

func listen(path string) (net.Listener, error) {
	return net.Listen("unix", path)
}

func initCommand(ctx echo.Context) error {
	cmd, err := exec.Command("/bin/sh", "-c", "echo 'toast").Output()
	if err != nil {
		fmt.Printf("error %s", err)
		output := string(cmd)
		errorString := fmt.Sprintf("error %s", err)
		return ctx.JSON(http.StatusOK, StartResponse{Output: output, Error: errorString})

	} else {
		output := string(cmd)
		return ctx.JSON(http.StatusOK, StartResponse{Output: output})
	}
}

type StartResponse struct {
	Output string
	Error  string
}
