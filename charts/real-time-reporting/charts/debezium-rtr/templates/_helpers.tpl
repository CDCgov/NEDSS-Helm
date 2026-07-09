{{/*
Expand the name of the chart.
*/}}
{{- define "debezium.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "debezium.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "debezium.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "debezium.labels.connect" -}}
helm.sh/chart: {{ include "debezium.chart" . }}
{{ include "debezium.selectorLabels.connect" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "debezium.labels.ui" -}}
helm.sh/chart: {{ include "debezium.chart" . }}
{{ include "debezium.selectorLabels.ui" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "debezium.selectorLabels.connect" -}}
app.kubernetes.io/name: {{ include "debezium.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/app: connect
{{- end }}

{{- define "debezium.selectorLabels.ui" -}}
app.kubernetes.io/name: {{ include "debezium.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/app: ui
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "debezium.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "debezium.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Resolve the connect image repository, preferring umbrella-level overrides.
*/}}
{{- define "debezium.connectImageRepository" -}}
{{- $global := default dict (fromYaml (toYaml $.Values.global)) -}}
{{- $images := default dict (index $global "images") -}}
{{- $debezium := default dict (index $images "debezium") -}}
{{- $connect := default dict (index $debezium "connect") -}}
{{- coalesce (index $connect "repository") .Values.connect.image.repository -}}
{{- end -}}

{{/*
Resolve the UI image repository, preferring umbrella-level overrides.
*/}}
{{- define "debezium.uiImageRepository" -}}
{{- $global := default dict (fromYaml (toYaml $.Values.global)) -}}
{{- $images := default dict (index $global "images") -}}
{{- $debezium := default dict (index $images "debezium") -}}
{{- $ui := default dict (index $debezium "ui") -}}
{{- coalesce (index $ui "repository") .Values.ui.image.repository -}}
{{- end -}}
