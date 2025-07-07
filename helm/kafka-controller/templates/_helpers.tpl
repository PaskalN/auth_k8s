{{- $ := . }}
{{- define "global.commonMetadata" }}
    {{- with $.Values.labels.custom }}
      {{- range $key, $value := . }}
        {{- if hasPrefix "Values." $value }}
          {{- $keys := split "." $value }}
          {{- if gt (len $keys) 1 }}

            
            {{- $current := $.Values }}

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
{{ $key }}: {{ $current | quote }}
            {{- end }}

          {{- end }}
        {{- else }}
{{ $key }}: {{ $value }}
        {{- end }}  
      {{- end }}
    {{- end}}

    {{- with $.Values.labels.kubernetes.io }}
      {{- range $key, $value := . }}
        {{- if hasPrefix "Values." $value }}
          {{- $keys := split "." $value }}
          {{- if gt (len $keys) 1 }}

            
            {{- $current := $.Values }}

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
app.kubernetes.io/{{ $key }}: {{ $current | quote }}
            {{- end }}

          {{- end }}
        {{- else }}
app.kubernetes.io/{{ $key }}: {{ $value }}
        {{- end }}  
      {{- end }}
    {{- end}}
{{- end }}
