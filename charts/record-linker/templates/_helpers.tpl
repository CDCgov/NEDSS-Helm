{{/*
Expand the name of the chart.
*/}}
{{- define "record-linker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "record-linker.fullname" -}}
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
{{- define "record-linker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "record-linker.labels" -}}
app: NBS
type: App
helm.sh/chart: {{ include "record-linker.chart" . }}
{{ include "record-linker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "record-linker.selectorLabels" -}}
app: NBS
type: App
app.kubernetes.io/name: {{ include "record-linker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "record-linker.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "record-linker.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the cert-manager credential to use
*/}}
{{- define "record-linker.certificateSecretName" -}}
{{- if .Values.istioGatewayIngress.enabled }}
{{- default (include "record-linker.fullname" .) .Values.istioGatewayIngress.certificateSecretName }}
{{- else }}
{{- default "default" .Values.ingress.certificateSecretName }}
{{- end }}
{{- end }}

{{/*
Create the name of the istio-ingress-gateway to use
*/}}
{{- define "record-linker.istioIngressGatewayName" -}}
{{- if .Values.istioGatewayIngress.enabled }}
{{- default (include "record-linker.fullname" .) .Values.istioGatewayIngress.istioIngressGatewayName }}
{{- else }}
{{- default "default" .Values.ingress.istioIngressGatewayName }}
{{- end }}
{{- end }}


