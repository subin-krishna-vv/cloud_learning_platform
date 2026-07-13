{{/*
     Helper file template for the Flask app chart.
    Use include to call the defined functions.
*/}}

{{/*
    Define the app name.
    Default to the chart name.
    Overriden with the nameOverride value.
    Truncated to 63 characters to meet the DNS-1123 requirements.
    Trimmed of any trailing hyphens.
*/}}
{{- define "app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/* 
    Define the full app name.
    Overriden with the fullnameOverride value.
    Otherwise, it is the release name concatenated with the app name.
    If the chart name contains the release name, it is just the release name.
    Otherwise, it is the release name concatenated with the chart name.
*/}}
{{- define "app.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $fullname := default .Chart.Name .Values.nameOverride -}}
{{- if contains $fullname .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $fullname | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
    Define the app namespace.
    Overriden with the namespaceOverride value.
    Otherwise, it is the release namespace.
*/}}
{{- define "app.namespace" -}}
{{- if .Values.namespaceOverride -}}
{{- .Values.namespaceOverride -}}
{{- else -}}
{{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{- define "app.chart" -}}
{{- $chartName := include "app.name" . -}}
{{- printf "%s-%s" $chartName .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
    Define the common labels.
*/}}
{{- define "app.commonlabels" -}}
helm.sh/chart: {{ include "app.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end -}}

{{/*
    Define the match labels.
*/}}
{{- define "app.selectorlabels" -}}
app: {{ .Values.appLabel }}
version: {{ .Values.versionLabel }}
{{- end -}}