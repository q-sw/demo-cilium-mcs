package main

import (
	"encoding/json"
	"html/template"
	"net/http"
	"os"
	"strings"
)

// UI Configuration based on location
type UITheme struct {
	Title      string `json:"title"`
	Color      string `json:"color"`
	Background string `json:"background"`
	Icon       string `json:"icon"`
	Location   string `json:"location"`
}

// Data passed to the HTML template
type PageData struct {
	ClusterName string  `json:"cluster_name"`
	Region      string  `json:"region"`
	PodName     string  `json:"pod_name"`
	PodIP       string  `json:"pod_ip"`
	NodeName    string  `json:"node_name"`
	Theme       UITheme `json:"theme"`
}

func getTheme(clusterName string) UITheme {
	// Default Theme
	theme := UITheme{
		Title:      "Unknown Cluster",
		Color:      "#6c757d",
		Background: "linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)",
		Icon:       "❓",
		Location:   "Unknown",
	}

	lowerName := strings.ToLower(clusterName)

	if strings.Contains(lowerName, "paris") {
		theme = UITheme{
			Title:      "Bonjour de Paris",
			Color:      "#0055A4",                                           // Blue
			Background: "linear-gradient(135deg, #e0c3fc 0%, #8ec5fc 100%)", // Soft Blue/Purple
			Icon:       "🗼",
			Location:   "Paris, France",
		}
	} else if strings.Contains(lowerName, "newyork") || strings.Contains(lowerName, "ny") {
		theme = UITheme{
			Title:      "Hello from New York",
			Color:      "#FF5E0E",                                           // NY Orange-ish
			Background: "linear-gradient(135deg, #fccb90 0%, #d57eeb 100%)", // Orange/Sunset
			Icon:       "🗽",
			Location:   "New York, USA",
		}
	}

	return theme
}

func getPageData() PageData {
	clusterName := os.Getenv("CLUSTER_NAME")
	if clusterName == "" {
		clusterName = "local-dev"
	}
	podName := os.Getenv("POD_NAME")
	if podName == "" {
		podName = os.Getenv("HOSTNAME")
	}
	podIP := os.Getenv("POD_IP")
	nodeName := os.Getenv("NODE_NAME")

	return PageData{
		ClusterName: clusterName,
		PodName:     podName,
		PodIP:       podIP,
		NodeName:    nodeName,
		Theme:       getTheme(clusterName),
	}
}

func handler(w http.ResponseWriter, r *http.Request) {
	data := getPageData()

	tmpl, err := template.New("index").Parse(htmlTemplate)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/html")
	tmpl.Execute(w, data)
}

func apiHandler(w http.ResponseWriter, r *http.Request) {
	data := getPageData()
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

func main() {
	http.HandleFunc("/", handler)
	http.HandleFunc("/api", apiHandler)
	port := "8080"
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		panic(err)
	}
}

// Embedded HTML Template with Bootstrap 5
const htmlTemplate = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{.Theme.Title}}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            background: {{.Theme.Background}};
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .card-custom {
            background: rgba(255, 255, 255, 0.9);
            border-radius: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            border: none;
            overflow: hidden;
            transition: transform 0.3s ease;
            max-width: 500px;
            width: 100%;
        }
        .card-custom:hover {
            transform: translateY(-5px);
        }
        .card-header-custom {
            background-color: {{.Theme.Color}};
            color: white;
            padding: 30px;
            text-align: center;
            font-size: 2rem;
            font-weight: bold;
        }
        .icon-large {
            font-size: 4rem;
            display: block;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .info-item {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #eee;
        }
        .info-item:last-child {
            border-bottom: none;
        }
        .label {
            font-weight: 600;
            color: #666;
        }
        .value {
            font-weight: 500;
            color: #333;
            font-family: 'Courier New', monospace;
        }
        .badge-custom {
            background-color: {{.Theme.Color}};
            color: white;
            padding: 5px 10px;
            border-radius: 10px;
            font-size: 0.8rem;
        }
    </style>
</head>
<body>

<div class="container p-3">
    <div class="card card-custom mx-auto">
        <div class="card-header-custom">
            <span class="icon-large">{{.Theme.Icon}}</span>
            {{.Theme.Title}}
        </div>
        <div class="card-body p-4">
            <div class="text-center mb-4">
                <span class="badge badge-custom">{{.Theme.Location}}</span>
            </div>

            <div class="info-item">
                <span class="label">Cluster</span>
                <span class="value">{{.ClusterName}}</span>
            </div>
            <div class="info-item">
                <span class="label">Pod Name</span>
                <span class="value">{{.PodName}}</span>
            </div>
            <div class="info-item">
                <span class="label">Pod IP</span>
                <span class="value">{{.PodIP}}</span>
            </div>
            <div class="info-item">
                <span class="label">Node</span>
                <span class="value">{{.NodeName}}</span>
            </div>
        </div>
        <div class="card-footer text-muted text-center py-3 bg-light">
            <small>Cilium Multi-Cluster Mesh Demo</small>
        </div>
    </div>
</div>

</body>
</html>
`
