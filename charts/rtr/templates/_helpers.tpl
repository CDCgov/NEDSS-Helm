{{/*
Generate fullname for the given serviceName key
*/}}
{{- define "fullname" -}}
{{- $serviceName := .serviceName | replace "." "-" -}}
{{- printf "%s-%s" .Release.Name $serviceName | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Generate serviceAccountName for the given serviceName
*/}}
{{- define "serviceAccountName" -}}
{{- include "fullname" . -}}
{{- end }}

{{/*
Common labels for all resources, using serviceName from dict
*/}}
{{- define "commonLabels" -}}
app.kubernetes.io/name: {{ .serviceName }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
