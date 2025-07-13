{{- define "dns.generator" }}

    {{- $root := .root }}
    {{- $object := .object }}

    {{- $set := list }}

    {{- range $i, $e := until (int $object.replicas) }}
        {{- $dns := print $object.pod_name "-" $i "." $object.service_name "." $object.namespace ".svc.cluster.local:" $object.port}}
        {{- $set = append $set $dns }}
    {{- end }}

    {{- $final := $set | join "," }}
        {{- if $final }}
{{- $final | quote}}
        {{- end}}

{{- end}}