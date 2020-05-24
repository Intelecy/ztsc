package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/esimov/triangle"
)

var (
	port int
)

func init() {
	rand.Seed(time.Now().UnixNano())

	flag.IntVar(&port, "port", 8080, "bind port")
	flag.Parse()
}

const content = `
<!doctype html>
<html lang="en">
    <head>
        <meta charset="utf-8">
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css" integrity="sha384-9aIt2nRpC12Uk9gS9baDl411NQApFmC26EwAOH8WgZl5MYYxFfc+NcPb1dKGj7Sk" crossorigin="anonymous">
        <title></title>
        <style type="text/css">
			body {
				background-color: %s;
			}
			body, a, a:link {
				color: %s;
			}
			svg {
				width: 100%%;
			}
			path {
				shape-rendering: geometricPrecision;
			}
			g {
				stroke-opacity: 20%%;
			}
        </style>
    </head>
    <body>
        <div class="container-fluid">
            <div class="row">
                <div class="col">
%s
                </div>
            </div>
            <div class="row">
                <div class="col text-center">
					<a href="%s">%s by %s</a> // Unsplash
				</div>
			</div>
        </div>
    </body>
</html>
`

type Unsplash struct {
	Photos struct {
		Results []struct {
			ID             string
			AltDescription string `json:"alt_description"`
			Color          string
			URLs           struct {
				Regular string
			}
			Links struct {
				HTML string
			}
			User struct {
				Name string
			}
		}
	}
}

func main() {
	ctx := CancelOnInterrupt(context.Background())

	log.Printf("listening on :%d", port)

	srv := &http.Server{
		Addr: fmt.Sprintf(":%d", port),
	}

	go func() {
		<-ctx.Done()
		log.Println("good bye!")
		_ = srv.Shutdown(ctx)
	}()

	resp, err := http.Get("https://unsplash.com/napi/search?query=colorful&per_page=30&orientation=landscape")
	if err != nil {
		log.Print(err)
		return
	}

	q := &Unsplash{}

	if err := json.NewDecoder(resp.Body).Decode(q); err != nil {
		log.Print(err)
		return
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/favicon.ico" {
			http.NotFound(w, r)
			return
		}

		start := time.Now()

		p := q.Photos.Results[rand.Intn(len(q.Photos.Results))]

		if p.AltDescription == "" {
			p.AltDescription = "Untitled"
		}

		resp, err := http.Get(p.URLs.Regular)

		log.Printf("fetch time: %s", time.Since(start))

		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			log.Print(err)
			return
		}

		if resp.Body != nil {
			defer resp.Body.Close()
		}

		if resp.StatusCode != http.StatusOK {
			w.WriteHeader(resp.StatusCode)
			io.Copy(w, resp.Body)
			return
		}

		start = time.Now()

		svg := &triangle.SVG{
			Processor: triangle.Processor{
				BlurRadius:      10,
				SobelThreshold:  10,
				PointsThreshold: 20,
				MaxPoints:       2500,
				Wireframe:       1,
				Noise:           100,
			},
			StrokeLineCap: "round",
			StrokeWidth:   5,
			Lines:         []triangle.Line{},
		}

		var buffer strings.Builder

		_, _, _, err = svg.Draw(resp.Body, &buffer, func() {})
		if err != nil {
			log.Print(err)
		}

		log.Printf("render time: %s", time.Since(start))

		fmt.Fprintf(
			w,
			content,
			p.Color,
			invert(p.Color),
			buffer.String(),
			p.Links.HTML,
			p.AltDescription,
			p.User.Name,
		)
	})

	if err := srv.ListenAndServe(); err != http.ErrServerClosed {
		// Error starting or closing listener:
		log.Fatalf("HTTP server ListenAndServe: %v", err)
	}
}

// CancelOnInterrupt handles SIGINT and SIGTERM by cancelling the context
func CancelOnInterrupt(ctx context.Context) context.Context {
	ctx, cancel := context.WithCancel(ctx)

	c := make(chan os.Signal, 1)
	signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		select {
		case <-ctx.Done():
		case <-c:
			println() // on Ctrl-C make terminal look a bit nicer
		}
		cancel()
	}()

	return ctx
}

func invert(color string) string {
	color = strings.ReplaceAll(color, "#", "")
	x, err := strconv.ParseInt(color, 16, 32)
	if err != nil {
		panic(err)
	}
	return fmt.Sprintf("#%06x", x^0xFFFFFF)
}
