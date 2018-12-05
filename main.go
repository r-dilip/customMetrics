package main

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"github.com/Azure/go-autorest/autorest"
	"github.com/Azure/go-autorest/autorest/azure/auth"
)

type metricItem struct {
	metricValue float64
	metricName  string
	nodeName    string
	metricTime  string
}

func getNodeMetricItem(metricJSON []byte, hostName string, metricCategory string, metricNameToCollect string, metricNametoReturn string) metricItem {
	var metricInfo map[string]interface{}
	//md, ok := mdi.(map[string]interface{})
	var item metricItem
	//clusterId = KubernetesApiClient.getClusterId
	if len(metricJSON) <= 0 {
		fmt.Println("Json input bytearray is empty")
		return item
	}

	//todo error handling
	err := json.Unmarshal(metricJSON, &metricInfo)
	if err != nil {
		fmt.Println("json.Unmarshal error", err)
	}
	var node = metricInfo["node"]
	var nd, _ = node.(map[string]interface{})
	var nodeName = nd["nodeName"]
	var category, _ = nd[metricCategory].(map[string]interface{})
	item.metricValue = category[metricNameToCollect].(float64)
	item.metricTime = category["time"].(string)
	item.nodeName = nodeName.(string)
	item.metricName = metricNametoReturn
	return item
}

func main() {

	MetricRefreshTicker := time.NewTicker(time.Second * time.Duration(60))

	for ; true; <-MetricRefreshTicker.C {

		// cacheContent := map[string]interface{}{
		// 	"foo": "bar",
		// 	"baz": map[string]interface{}{
		// 		"bee": "boo",
		// 	},
		// }
		data := map[string]interface{}{
			"time": time.Now().Format(time.RFC3339),
			"data": map[string]interface{}{
				"baseData": map[string]interface{}{
					"metric":    "QueueDepth",
					"namespace": "QueueProcessing",
					"dimNames": []string{
						"QueueName",
						"MessageType",
					},
					"series": []map[string]interface{}{
						map[string]interface{}{
							"dimValues": []string{
								"ImagesToProcess",
								"JPEG",
							},
							"min":   3,
							"max":   20,
							"sum":   28,
							"count": 3,
						},
					},
				},
			},
		}

		jsonBytes, err := json.Marshal(data)

		fmt.Printf("Sending metric %s", string(jsonBytes))
		err = send([]byte(jsonBytes))
		if err != nil {
			fmt.Printf("Error when sending %s", err.Error())
		}
	}
}

// func SendMetricToMDM(metric metricItem, config *Config) bool {
// 	resourceID := "/subscriptions/692aea0b-2d89-4e7e-ae30-fffe40782ee2/resourceGroups/jobyaks6/providers/Microsoft.ContainerService/managedClusters/jobyaks3"
// 	resourceRegion := "westcentralus"

// 	client := NewAzureClient(config, &publicAzureEnvironment)
// 	client.SendCustomMetricWithDimensions(
// 		resourceID,
// 		resourceRegion,
// 		metric.metricName,
// 		"CustomMetricNamespace",
// 		"NodeName",
// 		metric.nodeName,
// 		metric.metricValue,
// 		metric.metricValue,
// 		metric.metricValue,
// 		1)
// 	fmt.Println("NodeName: " + metric.nodeName + " MetricName:" + metric.metricName + "MetricValue:" + fmt.Sprintf("%f", metric.metricValue))
// 	return true
// }

func send(body []byte) error {
	var buf bytes.Buffer
	g := gzip.NewWriter(&buf)
	if _, err := g.Write(body); err != nil {
		return err
	}
	if err := g.Close(); err != nil {
		return err
	}

	client := &http.Client{
		Transport: &http.Transport{
			Proxy: http.ProxyFromEnvironment,
		},
	}

	// // query local MSI Endpoint to get token
	// vmInstanceMetadataURL := "http://169.254.169.254/metadata/instance?api-version=2017-12-01"
	// req0, err := http.NewRequest("GET", vmInstanceMetadataURL, nil)
	// if err != nil {
	// 	fmt.Printf("error creating request: %v", err)
	// }
	// req0.Header.Set("Metadata", "true")

	// resp0, err := client.Do(req0)
	// if err != nil {
	// 	fmt.Printf("error sending request: %v", err)
	// }
	// defer resp0.Body.Close()

	// respBody0, err := ioutil.ReadAll(resp0.Body)
	// if err != nil {
	// 	fmt.Printf("error reading response: %v", err)
	// }
	// if resp0.StatusCode >= 300 || resp0.StatusCode < 200 {
	// 	fmt.Printf("unable to fetch instance metadata: [%v] %s", resp0.StatusCode, respBody0)
	// }

	defaultAuthResource := "https://monitoring.azure.com/"
	// urlTemplate := "https://%s.monitoring.azure.com%s/metrics"
	// resourceIDTemplate := "/subscriptions/resourceGroups/%s/"
	// region := "eastus"
	// resourceID := fmt.Sprintf(
	// 	resourceIDTemplate,
	// 	"",
	// 	"acs-engine-test",
	// 	"",
	// )

	url := "https://eastus.monitoring.azure.com/subscriptions/72c8e8ca-dc16-47dc-b65c-6b5875eb600a/resourcegroups/acs-engine-test/providers/Microsoft.ContainerService/managedClusters/dilipr-watchapi/metrics"
	req1, err := http.NewRequest("POST", url, &buf)
	if err != nil {
		fmt.Printf("C %s", err.Error())
		return err
	}

	req1.Header.Set("Content-Encoding", "gzip")
	req1.Header.Set("Content-Type", "application/x-ndjson")

	auth, err := auth.NewAuthorizerFromEnvironmentWithResource(defaultAuthResource)
	if err != nil {
		fmt.Printf("\nunable to fetch authorizer: %v", err)
		return fmt.Errorf("\nunable to fetch authorizer: %v", err)
	}

	// Add the authorization header. WithAuthorization will automatically
	// refresh the token if needed.
	req1, err = autorest.CreatePreparer(auth.WithAuthorization()).Prepare(req1)
	if err != nil {
		fmt.Printf("\nunable to fetch authentication credentials: %v", err)
		return fmt.Errorf("unable to fetch authentication credentials: %v", err)
	}

	fmt.Println("\nSuccessfully prepared request and authenticated")

	resp1, err := client.Do(req1)
	if err != nil {
		return err
	}
	defer resp1.Body.Close()

	bodyBytes, err := ioutil.ReadAll(resp1.Body)
	if err != nil || resp1.StatusCode < 200 || resp1.StatusCode > 299 {
		fmt.Printf("\nfailed to write batch: [%v] %s", resp1.StatusCode, resp1.Status)
		fmt.Printf("\nBody = %s \n", string(bodyBytes))
		fmt.Println("HEADERS")
		for k, v := range resp1.Header {
			fmt.Print(k)
			fmt.Print(" : ")
			fmt.Println(v)
		}
		return fmt.Errorf("\nfailed to write batch: [%v] %s", resp1.StatusCode, resp1.Status)
	}

	return nil
}
