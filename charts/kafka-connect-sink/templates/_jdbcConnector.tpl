{{- define "jdbcConnector" }}
  echo "Installing Connector"
  confluent-hub install --no-prompt confluentinc/kafka-connect-jdbc:10.7.6

  echo "Spinning up worker"
  /etc/confluent/docker/run &

  echo "Waiting for the Kafka Connect worker to complete setup"
  while : ; do
    curl_status=$$(curl -s -o /dev/null -w %{http_code} http://localhost:8083/connectors)
    echo -e $$(date) " Kafka Connect listener HTTP state: " $$curl_status " (waiting for 200)"
    if [ $$curl_status -eq 200 ] ; then
      break
    fi
    sleep 10
  done

  echo "Starting sqlServerConnector"
  curl --request POST --header "Accept:application/json" --header "Content-Type:application/json" "http://127.0.0.1:8083/connectors/" --data "@/etc/sqlServerConnector.json"

  sleep infinity
{{- end }}