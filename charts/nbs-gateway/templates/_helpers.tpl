{{/*
Expand the name of the chart.
*/}}
{{- define "nbs-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "nbs-gateway.fullname" -}}
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
{{- define "nbs-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nbs-gateway.labels" -}}
app: NBS
type: App
helm.sh/chart: {{ include "nbs-gateway.chart" . }}
{{ include "nbs-gateway.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nbs-gateway.selectorLabels" -}}
app: NBS
type: App
app.kubernetes.io/name: {{ include "nbs-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "nbs-gateway.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nbs-gateway.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}




{{/*
Create the path to logo for configmap reference
*/}}
{{- define "nbs-gateway.logoPath" -}}
{{- if .Values.nbsLogoFilename }}
{{- printf "%s%s" "logos/" .Values.nbsLogoFilename }}
{{- else }}
{{- default "logos/nedssLogo.jpg" }}
{{- end }}
{{- end }}