{{/*
Expand the name of the chart.
*/}}
{{- define "sas-linux.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sas-linux.fullname" -}}
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
{{- define "sas-linux.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sas-linux.labels" -}}
app: NBS
type: App
helm.sh/chart: {{ include "sas-linux.chart" . }}
{{ include "sas-linux.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}

{{/*
ETL CronJob template
*/}}
{{- define "sas-linux.etl-cronjob" -}}
spec:
  template:
    spec:
      nodeSelector:
        kubernetes.io/os: linux
      containers:
      - name: {{ .name }}
        image: "{{ .root.Values.image.repository }}:{{ .root.Values.image.tag }}"
        imagePullPolicy: IfNotPresent
        env:
        - name: TZ
          value: "{{ .root.Values.etl.timezone }}"
        {{- range $key, $value := .root.Values.env }}
        - name: {{ $key }}
          value: "{{ $value }}"
        {{- end }}
        command:
        - /bin/bash
        - -c
        - |
          cd;
          export PATH="$PATH:/opt/mssql-tools18/bin";
          echo "Updating DB connections";
          sed -i -e "s/<TRACE_Yes_No>/$db_trace_on/g" /home/SAS/.odbc.ini;
          sed -i -e "s/<DB_HOST>/$db_host/g" /home/SAS/.odbc.ini;
          sed -i -e "s/<NBS_ODSE_USER>/$odse_user/g" /home/SAS/.odbc.ini;
          sed -i -e "s/<NBS_ODSE_PASS>/$odse_pass/g" /home/SAS/.odbc.ini;
          sed -i -e "s/<NBS_RDB_USER>/$rdb_user/g" /home/SAS/.odbc.ini;
          sed -i -e "s/<NBS_RDB_PASS>/$rdb_pass/g" /home/SAS/.odbc.ini;
          cp /home/SAS/.odbc.ini /etc/odbc.ini;
          chmod 766 /etc/odbc.ini;
          export ODBCINI=/etc/odbc.ini;
          echo "Updating autoexec.sas";
          autoexec_home="${WILDFLY_HOME}/wildfly-10.0.0.Final/nedssdomain/Nedss/report";
          sed -i "s|SAS_REPORT_HOME=.*|SAS_REPORT_HOME=$autoexec_home;|g" "$autoexec_home/autoexec.sas";
          sed -i "s|DSN=nedss1.*PASSWORD=.*s|DSN=nedss1 UID=$odse_user PASSWORD=$odse_pass|g" "$autoexec_home/autoexec.sas";
          sed -i "s|DSN=nbs_rdb.*PASSWORD=.*b|DSN=nbs_rdb UID=$rdb_user PASSWORD=$rdb_pass|g" "$autoexec_home/autoexec.sas";
          sed -i "s|DSN=nbs_srt.*PASSWORD=.*s|DSN=nbs_srt UID=$odse_user PASSWORD=$odse_pass|g" "$autoexec_home/autoexec.sas";
          sed -i "s|DSN=nbs_msg.*PASSWORD=.*s|DSN=nbs_msg UID=$odse_user PASSWORD=$odse_pass|g" "$autoexec_home/autoexec.sas";
          sed -i "s|let username=.*|let username=\"$rdb_user\";|g" "$autoexec_home/autoexec.sas";
          sed -i "s|let password=.*|let password=\"$rdb_pass\";|g" "$autoexec_home/autoexec.sas";
          date;
          echo 'Running PHCMartETL.sh';
          $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/BatchFiles/PHCMartETL.sh;
          ls -ltr $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log;
          echo '---- START PHCMartETL.log ERRORS ----';
          cat $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log/PHCMartETL.log | grep -i "error";
          echo '---- END PHCMartETL.log ERRORS ----';
          date;
          echo 'Running MasterEtl.sh';
          $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/BatchFiles/MasterEtl.sh;
          ls -ltr $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log;
          echo '---- START MasterETL1.lst ERRORS ----';
          cat $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log/MasterETL1.lst | grep -i "error";
          echo '---- END MasterETL1.lst ERRORS ----';
          echo '---- START Drop_Create_Tables.log ERRORS ----';
          cat $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log/Drop_Create_Tables.log | grep -i "error";
          echo '---- END Drop_Create_Tables.log ERRORS ----';
          echo '---- START MasterETL1.log ERRORS ----';
          cat $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log/MasterETL1.log | grep -i "error";
          echo '---- END MasterETL1.log ERRORS ----';
          echo '---- START MasterEtl2.log ERRORS ----';
          cat $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log/MasterEtl2.log | grep -i "error";
          echo '---- END MasterEtl2.log ERRORS ----';
          echo '---- START SSIS.log ERRORS ----';
          cat $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log/SSIS.log | grep -i "error";
          echo '---- END SSIS.log ERRORS ----';
          echo '---- START DynamicDatamart.log ERRORS ----';
          cat $WILDFLY_HOME/wildfly-10.0.0.Final/nedssdomain/Nedss/report/log/DynamicDatamart.log | grep -i "error";
          echo '---- END DynamicDatamart.log ERRORS ----';
          echo '---- START Checking rdb.dbo.job_batch_log for logged ERRORS ----';
          sqlcmd -S $db_host -U $rdb_user -P $rdb_pass -Q "select * from rdb.dbo.job_batch_log jbl where status_type <>'complete' and create_dttm > DATEADD(HOUR, -{{ .root.Values.etl.error_check_hours }}, CAST(CAST(GETDATE() AS DATE) AS DATETIME));" -W
          error_check_job_batch=$(sqlcmd -S $db_host -U $rdb_user -P $rdb_pass -Q "SET NOCOUNT ON; select * from rdb.dbo.job_batch_log jbl where status_type = 'error' and create_dttm > DATEADD(HOUR, -{{ .root.Values.etl.error_check_hours }}, CAST(CAST(GETDATE() AS DATE) AS DATETIME));" -W -h -1)
          if [[ $error_check_job_batch != "" ]]; then
              echo "ERROR: Found errors for the past {{ .root.Values.etl.error_check_hours }} hours in rdb.dbo.job_batch_log see log above"
              echo $error_check_job_batch
          fi
          echo '---- END Checking rdb.dbo.job_batch_log for logged ERRORS ----';
          echo '---- START Checking rdb.dbo.job_flow_log for logged ERRORS ----';
          sqlcmd -S $db_host -U $rdb_user -P $rdb_pass -Q "select * from rdb.dbo.job_flow_log jfl where Error_Description is not null and create_dttm > DATEADD(HOUR, -{{ .root.Values.etl.error_check_hours }}, CAST(CAST(GETDATE() AS DATE) AS DATETIME));" -W
          error_check_job_flow=$(sqlcmd -S $db_host -U $rdb_user -P $rdb_pass -Q "SET NOCOUNT ON; select * from rdb.dbo.job_flow_log jfl where Error_Description is not null and create_dttm > DATEADD(HOUR, -{{ .root.Values.etl.error_check_hours }}, CAST(CAST(GETDATE() AS DATE) AS DATETIME));" -W -h -1)
          if [[ $error_check_job_flow != "" ]]; then
              echo "ERROR: Found errors for the past {{ .root.Values.etl.error_check_hours }} hours in rdb.dbo.job_flow_log see log above"
          fi
          echo '---- END Checking rdb.dbo.job_flow_log for logged ERRORS ----';
      restartPolicy: Never
{{- end }}

{{- define "sas-linux.selectorLabels" -}}
app: NBS
type: ETL
app.kubernetes.io/name: {{ include "sas-linux.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sas-linux.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sas-linux.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
