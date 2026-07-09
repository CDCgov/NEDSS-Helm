{{/*
Common labels - standard Kubernetes labels for identifying the application and its version.
*/}}
{{- define "reporting-pipeline-service.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Values.image.tag }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "reporting-pipeline-service.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve the reporting pipeline image repository, preferring umbrella-level overrides.
*/}}
{{- define "reporting-pipeline-service.imageRepository" -}}
{{- $global := default dict (fromYaml (toYaml $.Values.global)) -}}
{{- $images := default dict (index $global "images") -}}
{{- $reporting := default dict (index $images "reportingPipelineService") -}}
{{- coalesce (index $reporting "repository") .Values.image.repository -}}
{{- end -}}
