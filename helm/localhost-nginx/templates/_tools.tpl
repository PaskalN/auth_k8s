{{- define "root.replace" }}
    {{- $root := .root }}
    {{- $value := .value }}

    {{- if hasPrefix "construct[" $value }}
        {{- include "tool.construct" (dict "root" $root "value" $value)}}
    {{- else if hasPrefix "Values." $value }}
        {{- $keys := split "." $value }}

        {{- if gt (len $keys) 1 }}
            {{- $current := $root.Values }}

            {{- range $keys }}
                {{- if eq . "Values" }}
                    {{- continue }}
                {{- end }}


                {{- if $current }}
                    {{- $current = index $current . }}
                {{- else }}
                    {{- break }}
                {{- end }}                
            {{- end }}

            {{- if $current }}
{{- $current | quote }}
            {{- else }}
{{- $value }}    
            {{- end }}
        {{- end }}
        
    {{- else }}
{{- $value }} 
    {{- end }}

{{- end}}


{{- define "tool.construct" }}
    {{- $root := .root }}
    {{- $value := .value }}
    {{- if hasPrefix "construct[" $value }}
        {{- $clean := $value | replace "construct[" "" | replace "]" "" | nospace }}

        {{- $items := splitList "," $clean }}
        {{- $set := list }}

        {{- if gt (len $items) 1 }}
            {{- range $items }}
                {{- $set = append $set (include "root.replace" (dict "root" $root "value" (printf "%v" .)) | nospace) }}
            {{- end}}
        {{- end}}

        {{- $final := $set | join "" }}
        {{- if $final }}
{{- $final | replace "\"" "" | quote}}
        {{- end}}

    {{- end}}
{{- end}}








{{- define "loop.array.values" }}
    {{- $root := .root }}
    {{- $type := typeOf .array }}
    {{- $template := .template }}

    {{- if eq $type "[]interface {}" }}
        
        {{- range .array }}
            {{- $v := include "root.replace" (dict "root" $root "value" (printf "%v" .)) | nospace }}

            {{- if not $template }}
{{$v}}
            {{- else }}
{{$template | replace "${item}" (printf "%v" $v) }}
            {{- end }}
        {{- end}}

    {{- end }}
{{- end }}


{{- define "loop.object.values" }}
    {{- $root := .root }}
    {{- $type := typeOf .object }}
    {{- $template := .template }}

    {{- if eq $type "map[string]interface {}" }}
        
        {{- range $key, $value := .object }}

            {{- $v := include "root.replace" (dict "root" $root "value" (printf "%v" $value)) -}}

            {{- if not $template }}
{{$key}}: {{$v}}
            {{- else }}
{{$template | replace "${key}" (printf "%v" $key) |  replace "${value}" (printf "%v" $v)}}
            {{- end }}
        {{- end}}

    {{- end }}
{{- end }}

