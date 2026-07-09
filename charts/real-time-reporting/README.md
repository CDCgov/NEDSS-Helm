# real-time-reporting

Umbrella chart for deploying:

- `debezium-rtr`
- `kafka-connect`
- `reporting-pipeline-service`

The subcharts live under `charts/real-time-reporting/charts/`.

## Install

```bash
helm upgrade --install real-time-reporting charts/real-time-reporting \
  --namespace <namespace> \
  --create-namespace \
  --values <environment-values.yaml> \
  --wait
```

## Image overrides

Set repository overrides once at the umbrella level:

```yaml
global:
  images:
    debezium:
      connect:
        repository: your-registry/debezium-connect
    kafkaConnect:
      repository: your-registry/kafka-connect
    reportingPipelineService:
      repository: your-registry/reporting-pipeline-service
```

## Notes

- Keep environment overrides in your own values file.
- Replace placeholder endpoints (for example `<namespace>`) before install.
- Reporting Pipeline Service should wait for Debezium and Kafka Connect before starting.
