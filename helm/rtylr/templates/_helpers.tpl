{{/* Common name helpers */}}
{{- define "rtylr.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "rtylr.labels" -}}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: rtylr
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/* Resolve the global image tag (image.tag overrides Chart.AppVersion) */}}
{{- define "rtylr.imageTag" -}}
{{- .Values.image.tag | default .Chart.AppVersion -}}
{{- end -}}

{{/* Build a full image ref for a given component name */}}
{{- define "rtylr.image" -}}
{{- $root := index . 0 -}}
{{- $name := index . 1 -}}
{{- printf "%s/%s/%s:%s" $root.Values.image.registry $root.Values.image.namespace $name (include "rtylr.imageTag" $root) -}}
{{- end -}}

{{/* Name of the env ConfigMap and Secret */}}
{{- define "rtylr.configMapName" -}}
{{- printf "%s-env" (include "rtylr.fullname" .) -}}
{{- end -}}

{{- define "rtylr.secretName" -}}
{{- printf "%s-secret" (include "rtylr.fullname" .) -}}
{{- end -}}

{{/* CORS origins derived from the configured frontend URLs */}}
{{- define "rtylr.corsOrigins" -}}
{{- $u := .Values.urls -}}
{{- printf "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" $u.auth $u.dash $u.pos $u.erp $u.hr $u.crm $u.finance $u.flow $u.insights $u.recruit $u.menu -}}
{{- end -}}

{{/* envFrom block shared by backend services */}}
{{- define "rtylr.backendEnvFrom" -}}
- configMapRef:
    name: {{ include "rtylr.configMapName" . }}
- secretRef:
    name: {{ if .Values.secrets.existingSecret }}{{ .Values.secrets.existingSecret }}{{ else }}{{ include "rtylr.secretName" . }}{{ end }}
{{- if .Values.license.existingSecret }}
- secretRef:
    name: {{ .Values.license.existingSecret }}
{{- end }}
{{- end -}}
