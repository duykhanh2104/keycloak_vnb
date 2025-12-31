{{- define "keycloak-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end }}

{{- define "keycloak-operator.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{ .Values.fullnameOverride }}
{{- else -}}
{{ include "keycloak-operator.name" . }}
{{- end -}}
{{- end }}
