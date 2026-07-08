# real-time-reporting

Umbrella chart for deploying:

- `debezium-rtr`
- `cp-kafka-connect`
- `reporting-pipeline-service`

## Install

```bash
helm dependency build charts/real-time-reporting
helm upgrade --install real-time-reporting charts/real-time-reporting \
  --namespace <namespace> \
  --create-namespace \
  --values <environment-values.yaml> \
  --wait
```

## Notes

- This chart depends on sibling charts in `charts/` via local `file://` dependencies.
- Keep environment overrides in your own values file.
- Replace placeholder endpoints (for example `<namespace>`) before install.
- Reporting Pipeline Service should wait for Debezium and Kafka Connect before starting.
