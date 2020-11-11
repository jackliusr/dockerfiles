#!/bin/sh
libpath=$(python3 -m site  | grep '/local/lib')
libv=${libpath:26:3}
for d in health \
health_surgery \
health_lifestyle \
health_services \
health_socioeconomics \
health_archives \
health_caldav \
health_calendar \
health_contact_tracing \
health_lab \
health_crypto \
health_crypto_lab \
health_ems \
health_federation \
health_genetics \
health_genetics_uniprot \
health_gyneco \
health_icd9procs \
health_icd10 \
health_icd10pcs \
health_icpm \
health_imaging \
health_inpatient \
health_inpatient_calendar \
health_insurance \
health_iss \
health_mdg6 \
health_ntd \
health_ntd_chagas \
health_ntd_dengue \
health_nursing \
health_icu \
health_ophthalmology \
health_orthanc \
health_pediatrics \
health_pediatrics_growth_charts \
health_pediatrics_growth_charts_who \
health_profile \
health_qrcodes \
health_reporting \
health_services_lab \
health_disability \
health_stock \
health_webdav3_server \
health_history \
health_who_essential_medicines; do
   echo "before install ${d}"
   #pip3 install --editable /tryton/${d}
   ln -si /tryton/${d} /usr/local/lib/python${libv}/dist-packages/trytond/modules/${d}
   echo "installed ${d}"
done 

ln -si /tryton/health_webdav3_server /usr/local/lib/python${libv}/dist-packages/trytond/modules/webdav
ln -si /tryton/health_caldav /usr/local/lib/python${libv}/dist-packages/trytond/modules/calendar
