{{/* App Name */}}
{{ define "platform-app.name" -}}
{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{ end -}}

{{/* App Full Name */}}
{{ define "platform-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{ .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name }}
{{ .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*helm/chart for audit and versioning*/}}
{{- define "platform-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Selector */}}
{{ define "platform-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "platform-app.name" .}}
app.kubernetes.io/instance: {{ .Release.Name }}
{{ end -}}

{{/* Standard Labels */}}
{{ define "platform-app.labels" -}}
helm.sh/chart: {{ include "platform-app.chart" .  }}
{{ include "platform-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* Service Account */}}
{{ define "platform-app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "platform-app.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end }}
{{- end }}