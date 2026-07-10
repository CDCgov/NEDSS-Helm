{{/*
Resolve the Debezium Connect service name using the nested chart's fullname convention.
*/}}
{{- define "real-time-reporting.debeziumConnectServiceName" -}}
{{- $name := "debezium" -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-connect" (.Release.Name | trunc 63 | trimSuffix "-") -}}
{{- else -}}
{{- printf "%s-connect" (printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-") -}}
{{- end -}}
{{- end -}}

{{/*
Resolve the Kafka Connect service name using the nested chart's fullname convention.
*/}}
{{- define "real-time-reporting.kafkaConnectServiceName" -}}
{{- $name := "kafka-connect" -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
