#!/bin/bash
# Nombre: generate_templates.sh
# Descripción: Script para generar 150 plantillas de documentos legales para inmigración

# Crear directorio si no existe
mkdir -p document_service/templates

# Función para crear plantillas JSON para cada tipo de documento
generate_template() {
    template_id=$1
    template_name=$2
    description=$3
    questions=$4
    sections=$5
    
    cat > "document_service/templates/${template_id}.json" << EOF
{
  "name": "${template_name}",
  "description": "${description}",
  "questions": ${questions},
  "sections": ${sections}
}
EOF
    echo "Creada plantilla: ${template_id}.json"
}

echo "Generando 150 plantillas de documentos legales para inmigración..."

# Grupos de plantillas por categorías
# 1. Peticiones familiares (I-130, etc.)
for i in {1..25}; do
    case $((i % 5)) in
        0)
            template_id="i130_spouse_${i}"
            template_name="I-130 Petición para Cónyuge"
            description="Formulario I-130 para petición de cónyuge"
            questions='[
                "Nombre completo del peticionario",
                "Número de seguro social del peticionario",
                "Dirección del peticionario",
                "Fecha de nacimiento del peticionario",
                "Lugar de nacimiento del peticionario",
                "Nombre completo del beneficiario",
                "Fecha de nacimiento del beneficiario",
                "País de nacimiento del beneficiario",
                "Fecha de matrimonio",
                "Lugar de matrimonio",
                "¿Ha estado casado anteriormente el peticionario?",
                "¿Ha estado casado anteriormente el beneficiario?",
                "Dirección actual del beneficiario",
                "Número A del beneficiario (si aplica)"
            ]'
            sections='{
                "header": "PETICIÓN PARA FAMILIAR EXTRANJERO\nFORMULARIO I-130",
                "petitioner_info": "INFORMACIÓN DEL PETICIONARIO\n\nNombre: {{nombre_completo_del_peticionario}}\nSSN: {{número_de_seguro_social_del_peticionario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_peticionario}}\nLugar de Nacimiento: {{lugar_de_nacimiento_del_peticionario}}\nDirección: {{dirección_del_peticionario}}",
                "beneficiary_info": "INFORMACIÓN DEL BENEFICIARIO\n\nNombre: {{nombre_completo_del_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_beneficiario}}\nPaís de Nacimiento: {{país_de_nacimiento_del_beneficiario}}\nDirección Actual: {{dirección_actual_del_beneficiario}}\nNúmero A (si aplica): {{número_a_del_beneficiario}}",
                "relationship_info": "INFORMACIÓN DE LA RELACIÓN\n\nFecha de Matrimonio: {{fecha_de_matrimonio}}\nLugar de Matrimonio: {{lugar_de_matrimonio}}\nMatrimonios Previos del Peticionario: {{¿ha_estado_casado_anteriormente_el_peticionario?}}\nMatrimonios Previos del Beneficiario: {{¿ha_estado_casado_anteriormente_el_beneficiario?}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Peticionario: ____________________\nFecha: ____________"
            }'
            ;;
        1)
            template_id="i130_child_${i}"
            template_name="I-130 Petición para Hijo/a"
            description="Formulario I-130 para petición de hijo/a"
            questions='[
                "Nombre completo del peticionario",
                "Número de seguro social del peticionario",
                "Dirección del peticionario",
                "Fecha de nacimiento del peticionario",
                "Lugar de nacimiento del peticionario",
                "Nombre completo del hijo/a beneficiario",
                "Fecha de nacimiento del hijo/a",
                "País de nacimiento del hijo/a",
                "Relación con el hijo/a (biológico, adoptado, hijastro)",
                "¿Vive actualmente el hijo/a con el peticionario?",
                "Dirección actual del hijo/a (si es diferente)",
                "Número A del hijo/a (si aplica)"
            ]'
            sections='{
                "header": "PETICIÓN PARA FAMILIAR EXTRANJERO\nFORMULARIO I-130 (HIJO/A)",
                "petitioner_info": "INFORMACIÓN DEL PETICIONARIO\n\nNombre: {{nombre_completo_del_peticionario}}\nSSN: {{número_de_seguro_social_del_peticionario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_peticionario}}\nLugar de Nacimiento: {{lugar_de_nacimiento_del_peticionario}}\nDirección: {{dirección_del_peticionario}}",
                "beneficiary_info": "INFORMACIÓN DEL HIJO/A BENEFICIARIO\n\nNombre: {{nombre_completo_del_hijo/a_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_hijo/a}}\nPaís de Nacimiento: {{país_de_nacimiento_del_hijo/a}}\nRelación: {{relación_con_el_hijo/a}}\nVive con peticionario: {{¿vive_actualmente_el_hijo/a_con_el_peticionario?}}\nDirección (si diferente): {{dirección_actual_del_hijo/a}}\nNúmero A (si aplica): {{número_a_del_hijo/a}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Peticionario: ____________________\nFecha: ____________"
            }'
            ;;
        2)
            template_id="i130_parent_${i}"
            template_name="I-130 Petición para Padre/Madre"
            description="Formulario I-130 para petición de padre o madre"
            questions='[
                "Nombre completo del peticionario ciudadano",
                "Número de seguro social del peticionario",
                "Dirección del peticionario",
                "Fecha de nacimiento del peticionario",
                "Lugar de nacimiento del peticionario",
                "Nombre completo del padre/madre beneficiario",
                "Fecha de nacimiento del padre/madre",
                "País de nacimiento del padre/madre",
                "Dirección actual del padre/madre",
                "Estado civil del padre/madre",
                "Número A del padre/madre (si aplica)"
            ]'
            sections='{
                "header": "PETICIÓN PARA FAMILIAR EXTRANJERO\nFORMULARIO I-130 (PADRE/MADRE)",
                "petitioner_info": "INFORMACIÓN DEL PETICIONARIO\n\nNombre: {{nombre_completo_del_peticionario_ciudadano}}\nSSN: {{número_de_seguro_social_del_peticionario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_peticionario}}\nLugar de Nacimiento: {{lugar_de_nacimiento_del_peticionario}}\nDirección: {{dirección_del_peticionario}}",
                "beneficiary_info": "INFORMACIÓN DEL PADRE/MADRE BENEFICIARIO\n\nNombre: {{nombre_completo_del_padre/madre_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_padre/madre}}\nPaís de Nacimiento: {{país_de_nacimiento_del_padre/madre}}\nDirección Actual: {{dirección_actual_del_padre/madre}}\nEstado Civil: {{estado_civil_del_padre/madre}}\nNúmero A (si aplica): {{número_a_del_padre/madre}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Peticionario: ____________________\nFecha: ____________"
            }'
            ;;
        3)
            template_id="i130_sibling_${i}"
            template_name="I-130 Petición para Hermano/a"
            description="Formulario I-130 para petición de hermano o hermana"
            questions='[
                "Nombre completo del peticionario ciudadano",
                "Número de seguro social del peticionario",
                "Dirección del peticionario",
                "Fecha de nacimiento del peticionario",
                "Lugar de nacimiento del peticionario",
                "Nombre completo del hermano/a beneficiario",
                "Fecha de nacimiento del hermano/a",
                "País de nacimiento del hermano/a",
                "Dirección actual del hermano/a",
                "Nombres de los padres",
                "Número A del hermano/a (si aplica)"
            ]'
            sections='{
                "header": "PETICIÓN PARA FAMILIAR EXTRANJERO\nFORMULARIO I-130 (HERMANO/A)",
                "petitioner_info": "INFORMACIÓN DEL PETICIONARIO\n\nNombre: {{nombre_completo_del_peticionario_ciudadano}}\nSSN: {{número_de_seguro_social_del_peticionario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_peticionario}}\nLugar de Nacimiento: {{lugar_de_nacimiento_del_peticionario}}\nDirección: {{dirección_del_peticionario}}",
                "beneficiary_info": "INFORMACIÓN DEL HERMANO/A BENEFICIARIO\n\nNombre: {{nombre_completo_del_hermano/a_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_hermano/a}}\nPaís de Nacimiento: {{país_de_nacimiento_del_hermano/a}}\nDirección Actual: {{dirección_actual_del_hermano/a}}\nNombres de los padres: {{nombres_de_los_padres}}\nNúmero A (si aplica): {{número_a_del_hermano/a}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Peticionario: ____________________\nFecha: ____________"
            }'
            ;;
        4)
            template_id="i129f_${i}"
            template_name="I-129F Petición para Prometido/a"
            description="Formulario I-129F para petición de visa K-1 (prometido/a)"
            questions='[
                "Nombre completo del peticionario ciudadano",
                "Número de seguro social del peticionario",
                "Dirección del peticionario",
                "Fecha de nacimiento del peticionario",
                "Lugar de nacimiento del peticionario",
                "Nombre completo del prometido/a beneficiario",
                "Fecha de nacimiento del prometido/a",
                "País de nacimiento del prometido/a",
                "Dirección actual del prometido/a",
                "¿Cómo se conocieron?",
                "Fecha del primer encuentro en persona",
                "Planes de matrimonio (fecha y lugar)",
                "Número A del prometido/a (si aplica)"
            ]'
            sections='{
                "header": "PETICIÓN PARA PROMETIDO/A EXTRANJERO\nFORMULARIO I-129F",
                "petitioner_info": "INFORMACIÓN DEL PETICIONARIO\n\nNombre: {{nombre_completo_del_peticionario_ciudadano}}\nSSN: {{número_de_seguro_social_del_peticionario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_peticionario}}\nLugar de Nacimiento: {{lugar_de_nacimiento_del_peticionario}}\nDirección: {{dirección_del_peticionario}}",
                "beneficiary_info": "INFORMACIÓN DEL PROMETIDO/A BENEFICIARIO\n\nNombre: {{nombre_completo_del_prometido/a_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento_del_prometido/a}}\nPaís de Nacimiento: {{país_de_nacimiento_del_prometido/a}}\nDirección Actual: {{dirección_actual_del_prometido/a}}\nNúmero A (si aplica): {{número_a_del_prometido/a}}",
                "relationship_info": "INFORMACIÓN DE LA RELACIÓN\n\nCómo se conocieron: {{¿cómo_se_conocieron?}}\nFecha del primer encuentro en persona: {{fecha_del_primer_encuentro_en_persona}}\nPlanes de matrimonio: {{planes_de_matrimonio}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Peticionario: ____________________\nFecha: ____________"
            }'
            ;;
    esac
    
    generate_template "$template_id" "$template_name" "$description" "$questions" "$sections"
done

# 2. Ajuste de estatus (I-485, etc.)
for i in {26..50}; do
    case $((i % 5)) in
        0)
            template_id="i485_family_${i}"
            template_name="I-485 Ajuste de Estatus Familiar"
            description="Formulario I-485 para ajuste de estatus basado en petición familiar"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Último ingreso a EE.UU. (fecha)",
                "Estatus actual",
                "Número de recibo de petición I-130",
                "Nombre del peticionario",
                "Relación con el peticionario",
                "Estado civil",
                "Información de empleo actual",
                "¿Ha sido arrestado alguna vez?"
            ]'
            sections='{
                "header": "SOLICITUD DE REGISTRO DE RESIDENCIA PERMANENTE\nFORMULARIO I-485 (FAMILIAR)",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}\nEstado Civil: {{estado_civil}}",
                "immigration_info": "INFORMACIÓN MIGRATORIA\n\nÚltimo ingreso a EE.UU.: {{último_ingreso_a_ee.uu.}}\nEstatus actual: {{estatus_actual}}\nNúmero de recibo I-130: {{número_de_recibo_de_petición_i130}}\nPeticionario: {{nombre_del_peticionario}}\nRelación: {{relación_con_el_peticionario}}",
                "additional_info": "INFORMACIÓN ADICIONAL\n\nEmpleo actual: {{información_de_empleo_actual}}\nArrestos previos: {{¿ha_sido_arrestado_alguna_vez?}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        1)
            template_id="i485_employment_${i}"
            template_name="I-485 Ajuste de Estatus Empleo"
            description="Formulario I-485 para ajuste de estatus basado en empleo"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Último ingreso a EE.UU. (fecha)",
                "Estatus actual",
                "Número de recibo de petición I-140",
                "Nombre del empleador patrocinador",
                "Categoría de preferencia de empleo",
                "Fecha de prioridad",
                "Estado civil",
                "Información de empleo actual",
                "¿Ha sido arrestado alguna vez?"
            ]'
            sections='{
                "header": "SOLICITUD DE REGISTRO DE RESIDENCIA PERMANENTE\nFORMULARIO I-485 (EMPLEO)",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}\nEstado Civil: {{estado_civil}}",
                "immigration_info": "INFORMACIÓN MIGRATORIA\n\nÚltimo ingreso a EE.UU.: {{último_ingreso_a_ee.uu.}}\nEstatus actual: {{estatus_actual}}\nNúmero de recibo I-140: {{número_de_recibo_de_petición_i140}}\nEmpleador: {{nombre_del_empleador_patrocinador}}\nCategoría: {{categoría_de_preferencia_de_empleo}}\nFecha de prioridad: {{fecha_de_prioridad}}",
                "additional_info": "INFORMACIÓN ADICIONAL\n\nEmpleo actual: {{información_de_empleo_actual}}\nArrestos previos: {{¿ha_sido_arrestado_alguna_vez?}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        2)
            template_id="i485_diversity_${i}"
            template_name="I-485 Ajuste de Estatus Lotería de Visas"
            description="Formulario I-485 para ajuste de estatus basado en lotería de visas"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Último ingreso a EE.UU. (fecha)",
                "Estatus actual",
                "Número de caso de lotería de visas (DV)",
                "Año fiscal de la lotería",
                "Estado civil",
                "Información de empleo actual",
                "¿Ha sido arrestado alguna vez?"
            ]'
            sections='{
                "header": "SOLICITUD DE REGISTRO DE RESIDENCIA PERMANENTE\nFORMULARIO I-485 (LOTERÍA DE VISAS)",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}\nEstado Civil: {{estado_civil}}",
                "immigration_info": "INFORMACIÓN MIGRATORIA\n\nÚltimo ingreso a EE.UU.: {{último_ingreso_a_ee.uu.}}\nEstatus actual: {{estatus_actual}}\nNúmero de caso DV: {{número_de_caso_de_lotería_de_visas}}\nAño fiscal: {{año_fiscal_de_la_lotería}}",
                "additional_info": "INFORMACIÓN ADICIONAL\n\nEmpleo actual: {{información_de_empleo_actual}}\nArrestos previos: {{¿ha_sido_arrestado_alguna_vez?}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        3)
            template_id="i485_asylee_${i}"
            template_name="I-485 Ajuste de Estatus Asilado"
            description="Formulario I-485 para ajuste de estatus basado en asilo"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Fecha de aprobación de asilo",
                "Oficina de asilo o corte que aprobó",
                "Estado civil",
                "Información de empleo actual",
                "¿Ha viajado fuera de EE.UU. desde la aprobación de asilo?",
                "¿Ha sido arrestado alguna vez?"
            ]'
            sections='{
                "header": "SOLICITUD DE REGISTRO DE RESIDENCIA PERMANENTE\nFORMULARIO I-485 (ASILADO)",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}\nEstado Civil: {{estado_civil}}",
                "immigration_info": "INFORMACIÓN MIGRATORIA\n\nFecha de aprobación de asilo: {{fecha_de_aprobación_de_asilo}}\nOficina/Corte que aprobó: {{oficina_de_asilo_o_corte_que_aprobó}}",
                "additional_info": "INFORMACIÓN ADICIONAL\n\nEmpleo actual: {{información_de_empleo_actual}}\nViajes fuera de EE.UU.: {{¿ha_viajado_fuera_de_ee.uu._desde_la_aprobación_de_asilo?}}\nArrestos previos: {{¿ha_sido_arrestado_alguna_vez?}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        4)
            template_id="i485_cover_letter_${i}"
            template_name="I-485 Carta de Presentación"
            description="Carta de presentación para paquete de I-485"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Categoría de ajuste (familiar, empleo, etc.)",
                "Número de recibo de petición subyacente",
                "Fecha de prioridad (si aplica)",
                "Lista de documentos incluidos",
                "Dirección de correspondencia",
                "Número de teléfono de contacto",
                "Correo electrónico"
            ]'
            sections='{
                "header": "CARTA DE PRESENTACIÓN\nSOLICITUD DE AJUSTE DE ESTATUS (I-485)",
                "addressed_to": "U.S. Citizenship and Immigration Services\nP.O. Box 805887\nChicago, IL 60680-4120",
                "intro": "RE: Solicitud de Ajuste de Estatus para {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nCategoría: {{categoría_de_ajuste}}\nRecibo de petición: {{número_de_recibo_de_petición_subyacente}}\nFecha de prioridad: {{fecha_de_prioridad}}",
                "body": "Estimado Oficial:\n\nAdjunto encontrará la Solicitud de Ajuste de Estatus (Formulario I-485) para {{nombre_completo_del_solicitante}}. Los siguientes documentos están incluidos en este paquete:\n\n{{lista_de_documentos_incluidos}}\n\nSi necesita información adicional o tiene alguna pregunta, no dude en contactarme.",
                "contact_info": "Atentamente,\n\n{{nombre_completo_del_solicitante}}\n{{dirección_de_correspondencia}}\nTeléfono: {{número_de_teléfono_de_contacto}}\nEmail: {{correo_electrónico}}"
            }'
            ;;
    esac
    
    generate_template "$template_id" "$template_name" "$description" "$questions" "$sections"
done

# 3. Permisos de trabajo (I-765)
for i in {51..65}; do
    template_id="i765_${i}"
    template_name="I-765 Autorización de Empleo"
    description="Solicitud de autorización de empleo"
    questions='[
        "Nombre completo del solicitante",
        "Número A (si aplica)",
        "Fecha de nacimiento",
        "País de nacimiento",
        "Dirección actual",
        "Género",
        "Estado civil",
        "Categoría de elegibilidad (ej. (c)(9), (c)(8))",
        "Base de solicitud (I-485 pendiente, asilo, etc.)",
        "Número de Seguro Social (si tiene)",
        "¿Es esta su primera solicitud de EAD?",
        "Fecha de vencimiento del último EAD (si aplica)"
    ]'
    sections='{
        "header": "SOLICITUD DE AUTORIZACIÓN DE EMPLEO\nFORMULARIO I-765",
        "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}\nGénero: {{género}}\nEstado Civil: {{estado_civil}}\nSSN: {{número_de_seguro_social}}",
        "eligibility_info": "INFORMACIÓN DE ELEGIBILIDAD\n\nCategoría: {{categoría_de_elegibilidad}}\nBase de solicitud: {{base_de_solicitud}}\nPrimera solicitud: {{¿es_esta_su_primera_solicitud_de_ead?}}\nFecha de vencimiento del último EAD: {{fecha_de_vencimiento_del_último_ead}}",
        "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
    }'
    
    generate_template "$template_id" "$template_name" "$description" "$questions" "$sections"
done

# 4. Exenciones (I-601, I-601A)
for i in {66..85}; do
    case $((i % 4)) in
        0)
            template_id="i601_criminal_${i}"
            template_name="I-601 Exención por Antecedentes Penales"
            description="Solicitud de exención por motivos de inadmisibilidad penal"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Bases de inadmisibilidad",
                "Descripción de los delitos/condenas",
                "Fechas de los delitos/condenas",
                "Familiares ciudadanos o residentes permanentes",
                "Relación con cada familiar",
                "Dificultades extremas que enfrentarían",
                "Evidencia de rehabilitación",
                "Tiempo en EE.UU.",
                "Contribuciones a la comunidad"
            ]'
            sections='{
                "header": "SOLICITUD DE EXENCIÓN DE INADMISIBILIDAD\nFORMULARIO I-601 (ANTECEDENTES PENALES)",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}",
                "inadmissibility_grounds": "BASES DE INADMISIBILIDAD\n\n{{bases_de_inadmisibilidad}}\n\nDescripción de delitos: {{descripción_de_los_delitos/condenas}}\nFechas: {{fechas_de_los_delitos/condenas}}",
                "hardship_info": "DIFICULTADES EXTREMAS\n\nFamiliares calificados: {{familiares_ciudadanos_o_residentes_permanentes}}\nRelación: {{relación_con_cada_familiar}}\nDificultades: {{dificultades_extremas_que_enfrentarían}}",
                "rehabilitation": "REHABILITACIÓN Y FACTORES POSITIVOS\n\nEvidencia de rehabilitación: {{evidencia_de_rehabilitación}}\nTiempo en EE.UU.: {{tiempo_en_ee.uu.}}\nContribuciones a la comunidad: {{contribuciones_a_la_comunidad}}",
                "conclusion": "Por las razones anteriores, solicito respetuosamente que se apruebe esta solicitud de exención.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        1)
            template_id="i601_fraud_${i}"
            template_name="I-601 Exención por Fraude/Tergiversación"
            description="Solicitud de exención por motivos de inadmisibilidad por fraude o tergiversación"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Descripción del fraude o tergiversación",
                "Fecha del fraude o tergiversación",
                "Familiares ciudadanos o residentes permanentes",
                "Relación con cada familiar",
                "Dificultades extremas que enfrentarían",
                "Circunstancias atenuantes",
                "Tiempo en EE.UU.",
                "Contribuciones a la comunidad"
            ]'
            sections='{
                "header": "SOLICITUD DE EXENCIÓN DE INADMISIBILIDAD\nFORMULARIO I-601 (FRAUDE/TERGIVERSACIÓN)",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}",
                "inadmissibility_grounds": "BASES DE INADMISIBILIDAD\n\nDescripción del fraude: {{descripción_del_fraude_o_tergiversación}}\nFecha: {{fecha_del_fraude_o_tergiversación}}",
                "hardship_info": "DIFICULTADES EXTREMAS\n\nFamiliares calificados: {{familiares_ciudadanos_o_residentes_permanentes}}\nRelación: {{relación_con_cada_familiar}}\nDificultades: {{dificultades_extremas_que_enfrentarían}}",
                "mitigating_factors": "CIRCUNSTANCIAS ATENUANTES Y FACTORES POSITIVOS\n\nCircunstancias atenuantes: {{circunstancias_atenuantes}}\nTiempo en EE.UU.: {{tiempo_en_ee.uu.}}\nContribuciones a la comunidad: {{contribuciones_a_la_comunidad}}",
                "conclusion": "Por las razones anteriores, solicito respetuosamente que se apruebe esta solicitud de exención.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        2)
            template_id="i601_unlawful_presence_${i}"
            template_name="I-601 Exención por Presencia Ilegal"
            description="Solicitud de exención por motivos de presencia ilegal (3/10 años)"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Período de presencia ilegal",
                "Fecha de salida de EE.UU.",
                "Familiar ciudadano o residente permanente",
                "Relación con el familiar",
                "Dificultades médicas que enfrentaría el familiar",
                "Dificultades financieras que enfrentaría el familiar",
                "Dificultades emocionales que enfrentaría el familiar",
                "Condiciones en el país de origen",
                "Lazos familiares en EE.UU."
            ]'
            sections='{
                "header": "SOLICITUD DE EXENCIÓN DE INADMISIBILIDAD\nFORMULARIO I-601 (PRESENCIA ILEGAL)",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}",
                "inadmissibility_grounds": "BASES DE INADMISIBILIDAD\n\nPeríodo de presencia ilegal: {{período_de_presencia_ilegal}}\nFecha de salida: {{fecha_de_salida_de_ee.uu.}}",
                "qualifying_relative": "FAMILIAR CALIFICADO\n\nFamiliar: {{familiar_ciudadano_o_residente_permanente}}\nRelación: {{relación_con_el_familiar}}",
                "medical_hardship": "DIFICULTADES MÉDICAS\n\n{{dificultades_médicas_que_enfrentaría_el_familiar}}",
                "financial_hardship": "DIFICULTADES FINANCIERAS\n\n{{dificultades_financieras_que_enfrentaría_el_familiar}}",
                "emotional_hardship": "DIFICULTADES EMOCIONALES\n\n{{dificultades_emocionales_que_enfrentaría_el_familiar}}",
                "country_conditions": "CONDICIONES EN EL PAÍS DE ORIGEN\n\n{{condiciones_en_el_país_de_origen}}",
                "family_ties": "LAZOS FAMILIARES EN EE.UU.\n\n{{lazos_familiares_en_ee.uu.}}",
                "conclusion": "Por las razones anteriores, solicito respetuosamente que se apruebe esta solicitud de exención.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        3)
            template_id="i601a_${i}"
            template_name="I-601A Exención Provisional"
            description="Solicitud de exención provisional por presencia ilegal"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Período de presencia ilegal",
                "Número de caso de petición familiar aprobada",
                "Relación con el peticionario",
                "Cónyuge ciudadano o residente permanente",
                "Padres ciudadanos o residentes permanentes",
                "Dificultades extremas que enfrentaría el familiar",
                "Lazos familiares en EE.UU.",
                "Condiciones en el país de origen",
                "Fecha programada de entrevista consular (si se conoce)"
            ]'
            sections='{
                "header": "SOLICITUD DE EXENCIÓN PROVISIONAL\nFORMULARIO I-601A",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}",
                "immigration_info": "INFORMACIÓN MIGRATORIA\n\nPeríodo de presencia ilegal: {{período_de_presencia_ilegal}}\nNúmero de caso de petición: {{número_de_caso_de_petición_familiar_aprobada}}\nRelación con peticionario: {{relación_con_el_peticionario}}\nEntrevista consular programada: {{fecha_programada_de_entrevista_consular}}",
                "qualifying_relatives": "FAMILIARES CALIFICADOS\n\nCónyuge: {{cónyuge_ciudadano_o_residente_permanente}}\nPadres: {{padres_ciudadanos_o_residentes_permanentes}}",
                "extreme_hardship": "DIFICULTADES EXTREMAS\n\n{{dificultades_extremas_que_enfrentaría_el_familiar}}",
                "additional_factors": "FACTORES ADICIONALES\n\nLazos familiares en EE.UU.: {{lazos_familiares_en_ee.uu.}}\nCondiciones en país de origen: {{condiciones_en_el_país_de_origen}}",
                "conclusion": "Por las razones anteriores, solicito respetuosamente que se apruebe esta solicitud de exención provisional.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
    esac
    
    generate_template "$template_id" "$template_name" "$description" "$questions" "$sections"
done

# 5. Naturalización (N-400)
for i in {86..100}; do
    template_id="n400_${i}"
    template_name="N-400 Solicitud de Naturalización"
    description="Solicitud de naturalización para convertirse en ciudadano estadounidense"
    questions='[
        "Nombre completo del solicitante",
        "Número A",
        "Fecha de nacimiento",
        "País de nacimiento",
        "Dirección actual",
        "Fecha de obtención de residencia permanente",
        "Base de elegibilidad (5 años, 3 años casado con ciudadano, militar)",
        "Estado civil",
        "Nombre del cónyuge (si aplica)",
        "Estatus migratorio del cónyuge",
        "¿Ha estado fuera de EE.UU. más de 6 meses?",
        "Detalles de viajes al exterior",
        "Historial de empleo (últimos 5 años)",
        "Historial de residencia (últimos 5 años)",
        "¿Ha sido arrestado alguna vez?",
        "Detalles de arrestos o condenas (si aplica)",
        "Organizaciones a las que pertenece"
    ]'
    sections='{
        "header": "SOLICITUD DE NATURALIZACIÓN\nFORMULARIO N-400",
        "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}\nEstado Civil: {{estado_civil}}",
        "immigration_info": "INFORMACIÓN MIGRATORIA\n\nFecha de residencia permanente: {{fecha_de_obtención_de_residencia_permanente}}\nBase de elegibilidad: {{base_de_elegibilidad}}\nCónyuge: {{nombre_del_cónyuge}}\nEstatus del cónyuge: {{estatus_migratorio_del_cónyuge}}",
        "absence_info": "AUSENCIAS DE EE.UU.\n\nAusencias de más de 6 meses: {{¿ha_estado_fuera_de_ee.uu._más_de_6_meses?}}\nDetalles de viajes: {{detalles_de_viajes_al_exterior}}",
        "residence_employment": "RESIDENCIA Y EMPLEO\n\nHistorial de residencia: {{historial_de_residencia}}\nHistorial de empleo: {{historial_de_empleo}}",
        "good_moral_character": "BUEN CARÁCTER MORAL\n\nArrestos: {{¿ha_sido_arrestado_alguna_vez?}}\nDetalles: {{detalles_de_arrestos_o_condenas}}\nOrganizaciones: {{organizaciones_a_las_que_pertenece}}",
        "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
    }'
    
    generate_template "$template_id" "$template_name" "$description" "$questions" "$sections"
done

# 6. TPS, DACA, y otros programas especiales
for i in {101..115}; do
    case $((i % 3)) in
        0)
            template_id="tps_initial_${i}"
            template_name="TPS Solicitud Inicial"
            description="Solicitud inicial de Estatus de Protección Temporal"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Nacionalidad",
                "Dirección actual",
                "Fecha de entrada a EE.UU.",
                "Estatus al entrar",
                "País designado para TPS",
                "Evidencia de nacionalidad",
                "Evidencia de presencia física",
                "Evidencia de residencia continua",
                "¿Ha sido condenado por algún delito?"
            ]'
            sections='{
                "header": "SOLICITUD DE ESTATUS DE PROTECCIÓN TEMPORAL (TPS)\nFORMULARIO I-821",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nNacionalidad: {{nacionalidad}}\nDirección: {{dirección_actual}}",
                "immigration_info": "INFORMACIÓN MIGRATORIA\n\nFecha de entrada: {{fecha_de_entrada_a_ee.uu.}}\nEstatus al entrar: {{estatus_al_entrar}}\nPaís designado para TPS: {{país_designado_para_tps}}",
                "eligibility_evidence": "EVIDENCIA DE ELEGIBILIDAD\n\nNacionalidad: {{evidencia_de_nacionalidad}}\nPresencia física: {{evidencia_de_presencia_física}}\nResidencia continua: {{evidencia_de_residencia_continua}}",
                "criminal_history": "HISTORIAL PENAL\n\nCondenas: {{¿ha_sido_condenado_por_algún_delito?}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        1)
            template_id="daca_initial_${i}"
            template_name="DACA Solicitud Inicial"
            description="Solicitud inicial de Acción Diferida para los Llegados en la Infancia"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Fecha de entrada a EE.UU.",
                "Edad al entrar a EE.UU.",
                "Prueba de presencia en EE.UU. el 15 de junio de 2012",
                "Prueba de residencia continua desde el 15 de junio de 2007",
                "Estatus educativo actual",
                "Historial educativo",
                "¿Ha sido condenado por algún delito?",
                "¿Ha servido en las fuerzas armadas?"
            ]'
            sections='{
                "header": "SOLICITUD DE ACCIÓN DIFERIDA PARA LOS LLEGADOS EN LA INFANCIA (DACA)\nFORMULARIO I-821D",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}",
                "immigration_info": "INFORMACIÓN MIGRATORIA\n\nFecha de entrada: {{fecha_de_entrada_a_ee.uu.}}\nEdad al entrar: {{edad_al_entrar_a_ee.uu.}}",
                "eligibility_evidence": "EVIDENCIA DE ELEGIBILIDAD\n\nPresencia el 15/06/2012: {{prueba_de_presencia_en_ee.uu._el_15_de_junio_de_2012}}\nResidencia continua desde 15/06/2007: {{prueba_de_residencia_continua_desde_el_15_de_junio_de_2007}}\nEstatus educativo: {{estatus_educativo_actual}}\nHistorial educativo: {{historial_educativo}}\nServicio militar: {{¿ha_servido_en_las_fuerzas_armadas?}}",
                "criminal_history": "HISTORIAL PENAL\n\nCondenas: {{¿ha_sido_condenado_por_algún_delito?}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
        2)
            template_id="u_visa_${i}"
            template_name="U Visa Solicitud"
            description="Solicitud de visa U para víctimas de delitos"
            questions='[
                "Nombre completo del solicitante",
                "Número A (si aplica)",
                "Fecha de nacimiento",
                "País de nacimiento",
                "Dirección actual",
                "Tipo de delito del que fue víctima",
                "Fecha del delito",
                "Lugar del delito",
                "Agencia policial donde se reportó",
                "Número de reporte policial",
                "Descripción del daño físico o mental sufrido",
                "Asistencia proporcionada a las autoridades",
                "Familiares que desea incluir como derivados"
            ]'
            sections='{
                "header": "SOLICITUD DE ESTATUS DE NO INMIGRANTE U\nFORMULARIO I-918",
                "personal_info": "INFORMACIÓN PERSONAL\n\nNombre: {{nombre_completo_del_solicitante}}\nNúmero A: {{número_a}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nDirección: {{dirección_actual}}",
                "criminal_activity": "ACTIVIDAD CRIMINAL CALIFICADA\n\nTipo de delito: {{tipo_de_delito_del_que_fue_víctima}}\nFecha: {{fecha_del_delito}}\nLugar: {{lugar_del_delito}}\nAgencia policial: {{agencia_policial_donde_se_reportó}}\nNúmero de reporte: {{número_de_reporte_policial}}",
                "harm_suffered": "DAÑO SUFRIDO\n\n{{descripción_del_daño_físico_o_mental_sufrido}}",
                "law_enforcement": "ASISTENCIA A LAS AUTORIDADES\n\n{{asistencia_proporcionada_a_las_autoridades}}",
                "derivatives": "BENEFICIARIOS DERIVADOS\n\n{{familiares_que_desea_incluir_como_derivados}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta según mi conocimiento.\n\nFirma del Solicitante: ____________________\nFecha: ____________"
            }'
            ;;
    esac
    
    generate_template "$template_id" "$template_name" "$description" "$questions" "$sections"
done

# 7. Peticiones de empleo (I-140) y categorías especiales
for i in {116..140}; do
    case $((i % 5)) in
        0)
            template_id="i140_eb1_${i}"
            template_name="I-140 Petición EB-1"
            description="Petición de inmigrante para trabajador prioritario (EB-1)"
            questions='[
                "Nombre completo del beneficiario",
                "Fecha de nacimiento",
                "País de nacimiento",
                "País de nacionalidad",
                "Dirección actual",
                "Subcategoría EB-1 (habilidad extraordinaria, profesor/investigador, multinacional)",
                "Posición actual",
                "Credenciales académicas",
                "Principales logros profesionales",
                "Reconocimientos o premios",
                "Membresías profesionales",
                "Publicaciones",
                "Cartas de recomendación disponibles",
                "Evidencia de salario superior al promedio"
            ]'
            sections='{
                "header": "PETICIÓN DE INMIGRANTE PARA TRABAJADOR PRIORITARIO (EB-1)\nFORMULARIO I-140",
                "beneficiary_info": "INFORMACIÓN DEL BENEFICIARIO\n\nNombre: {{nombre_completo_del_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nNacionalidad: {{país_de_nacionalidad}}\nDirección: {{dirección_actual}}",
                "eb1_category": "CATEGORÍA EB-1\n\nSubcategoría: {{subcategoría_eb1}}\nPosición actual: {{posición_actual}}",
                "qualifications": "CALIFICACIONES\n\nCredenciales académicas: {{credenciales_académicas}}\nLogros profesionales: {{principales_logros_profesionales}}\nReconocimientos/Premios: {{reconocimientos_o_premios}}\nMembresías: {{membresías_profesionales}}",
                "evidence": "EVIDENCIA\n\nPublicaciones: {{publicaciones}}\nCartas de recomendación: {{cartas_de_recomendación_disponibles}}\nSalario superior: {{evidencia_de_salario_superior_al_promedio}}",
                "conclusion": "Con base en las calificaciones y evidencias presentadas, se solicita la aprobación de esta petición EB-1.\n\nFirma: ____________________\nFecha: ____________"
            }'
            ;;
        1)
            template_id="i140_eb2_${i}"
            template_name="I-140 Petición EB-2"
            description="Petición de inmigrante para profesional con título avanzado o habilidad excepcional (EB-2)"
            questions='[
                "Nombre completo del beneficiario",
                "Fecha de nacimiento",
                "País de nacimiento",
                "País de nacionalidad",
                "Dirección actual",
                "Subcategoría EB-2 (título avanzado, habilidad excepcional, NIW)",
                "Posición ofrecida",
                "Empleador peticionario (si aplica)",
                "Título académico",
                "Universidad/institución",
                "Años de experiencia profesional",
                "Salario ofrecido",
                "Número de caso de certificación laboral (si aplica)",
                "Justificación para exención de certificación laboral (si NIW)"
            ]'
            sections='{
                "header": "PETICIÓN DE INMIGRANTE PARA PROFESIONAL (EB-2)\nFORMULARIO I-140",
                "beneficiary_info": "INFORMACIÓN DEL BENEFICIARIO\n\nNombre: {{nombre_completo_del_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nNacionalidad: {{país_de_nacionalidad}}\nDirección: {{dirección_actual}}",
                "eb2_category": "CATEGORÍA EB-2\n\nSubcategoría: {{subcategoría_eb2}}\nPosición ofrecida: {{posición_ofrecida}}\nEmpleador (si aplica): {{empleador_peticionario}}",
                "qualifications": "CALIFICACIONES\n\nTítulo académico: {{título_académico}}\nUniversidad: {{universidad/institución}}\nExperiencia profesional: {{años_de_experiencia_profesional}}",
                "labor_certification": "CERTIFICACIÓN LABORAL\n\nSalario ofrecido: {{salario_ofrecido}}\nNúmero de caso: {{número_de_caso_de_certificación_laboral}}",
                "niw_justification": "JUSTIFICACIÓN PARA NIW (si aplica)\n\n{{justificación_para_exención_de_certificación_laboral}}",
                "conclusion": "Con base en las calificaciones y evidencias presentadas, se solicita la aprobación de esta petición EB-2.\n\nFirma: ____________________\nFecha: ____________"
            }'
            ;;
        2)
            template_id="i140_eb3_${i}"
            template_name="I-140 Petición EB-3"
            description="Petición de inmigrante para trabajador profesional, calificado o no calificado (EB-3)"
            questions='[
                "Nombre completo del beneficiario",
                "Fecha de nacimiento",
                "País de nacimiento",
                "País de nacionalidad",
                "Dirección actual",
                "Subcategoría EB-3 (profesional, trabajador calificado, otro)",
                "Posición ofrecida",
                "Nombre del empleador peticionario",
                "Dirección del empleador",
                "Calificaciones requeridas para el puesto",
                "Calificaciones del beneficiario",
                "Experiencia laboral relevante",
                "Salario ofrecido",
                "Número de caso de certificación laboral"
            ]'
            sections='{
                "header": "PETICIÓN DE INMIGRANTE PARA TRABAJADOR (EB-3)\nFORMULARIO I-140",
                "beneficiary_info": "INFORMACIÓN DEL BENEFICIARIO\n\nNombre: {{nombre_completo_del_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nNacionalidad: {{país_de_nacionalidad}}\nDirección: {{dirección_actual}}",
                "eb3_category": "CATEGORÍA EB-3\n\nSubcategoría: {{subcategoría_eb3}}",
                "job_offer": "OFERTA DE TRABAJO\n\nPosición ofrecida: {{posición_ofrecida}}\nEmpleador: {{nombre_del_empleador_peticionario}}\nDirección del empleador: {{dirección_del_empleador}}",
                "qualifications": "CALIFICACIONES\n\nRequeridas para el puesto: {{calificaciones_requeridas_para_el_puesto}}\nCalificaciones del beneficiario: {{calificaciones_del_beneficiario}}\nExperiencia laboral: {{experiencia_laboral_relevante}}",
                "labor_certification": "CERTIFICACIÓN LABORAL\n\nSalario ofrecido: {{salario_ofrecido}}\nNúmero de caso: {{número_de_caso_de_certificación_laboral}}",
                "conclusion": "Con base en las calificaciones y evidencias presentadas, se solicita la aprobación de esta petición EB-3.\n\nFirma: ____________________\nFecha: ____________"
            }'
            ;;
        3)
            template_id="perm_labor_cert_${i}"
            template_name="PERM Certificación Laboral"
            description="Solicitud de certificación laboral permanente (PERM)"
            questions='[
                "Nombre del empleador",
                "Dirección del empleador",
                "Tipo de negocio",
                "Persona de contacto",
                "Número de teléfono",
                "Correo electrónico",
                "Título del puesto ofrecido",
                "Deberes del puesto",
                "Requisitos educativos",
                "Experiencia requerida",
                "Ubicación del trabajo",
                "Salario ofrecido",
                "Esfuerzos de reclutamiento realizados",
                "Nombre del trabajador extranjero",
                "Calificaciones del trabajador extranjero"
            ]'
            sections='{
                "header": "SOLICITUD DE CERTIFICACIÓN LABORAL PERMANENTE (PERM)\nFORMULARIO ETA 9089",
                "employer_info": "INFORMACIÓN DEL EMPLEADOR\n\nNombre: {{nombre_del_empleador}}\nDirección: {{dirección_del_empleador}}\nTipo de negocio: {{tipo_de_negocio}}\nContacto: {{persona_de_contacto}}\nTeléfono: {{número_de_teléfono}}\nEmail: {{correo_electrónico}}",
                "job_info": "INFORMACIÓN DEL PUESTO\n\nTítulo: {{título_del_puesto_ofrecido}}\nDeberes: {{deberes_del_puesto}}\nRequisitos educativos: {{requisitos_educativos}}\nExperiencia requerida: {{experiencia_requerida}}\nUbicación: {{ubicación_del_trabajo}}\nSalario: {{salario_ofrecido}}",
                "recruitment": "ESFUERZOS DE RECLUTAMIENTO\n\n{{esfuerzos_de_reclutamiento_realizados}}",
                "worker_info": "INFORMACIÓN DEL TRABAJADOR EXTRANJERO\n\nNombre: {{nombre_del_trabajador_extranjero}}\nCalificaciones: {{calificaciones_del_trabajador_extranjero}}",
                "declaration": "Certifico que la información proporcionada es verdadera y correcta. El empleador ha hecho esfuerzos de buena fe para reclutar trabajadores estadounidenses para la posición y no ha podido encontrar un trabajador estadounidense que esté igualmente o mejor calificado que el trabajador extranjero.\n\nFirma del Empleador: ____________________\nFecha: ____________"
            }'
            ;;
        4)
            template_id="o1_petition_${i}"
            template_name="O-1 Petición para Extranjero de Habilidad Extraordinaria"
            description="Petición para visa O-1 por habilidad extraordinaria"
            questions='[
                "Nombre completo del beneficiario",
                "Fecha de nacimiento",
                "País de nacimiento",
                "País de nacionalidad",
                "Dirección actual",
                "Campo de especialización",
                "Eventos o proyectos específicos",
                "Fechas de empleo solicitadas",
                "Premios o reconocimientos recibidos",
                "Membresías en asociaciones selectas",
                "Publicaciones o contribuciones al campo",
                "Evidencia de salario elevado",
                "Participación como juez del trabajo de otros",
                "Contribuciones originales significativas",
                "Nombre del peticionario/empleador",
                "Itinerario de actividades propuestas"
            ]'
            sections='{
                "header": "PETICIÓN PARA TRABAJADOR NO INMIGRANTE O-1\nFORMULARIO I-129/O",
                "beneficiary_info": "INFORMACIÓN DEL BENEFICIARIO\n\nNombre: {{nombre_completo_del_beneficiario}}\nFecha de Nacimiento: {{fecha_de_nacimiento}}\nPaís de Nacimiento: {{país_de_nacimiento}}\nNacionalidad: {{país_de_nacionalidad}}\nDirección: {{dirección_actual}}",
                "petition_details": "DETALLES DE LA PETICIÓN\n\nCampo de especialización: {{campo_de_especialización}}\nEventos/proyectos: {{eventos_o_proyectos_específicos}}\nFechas solicitadas: {{fechas_de_empleo_solicitadas}}\nPeticionario/empleador: {{nombre_del_peticionario/empleador}}",
                "extraordinary_ability": "EVIDENCIA DE HABILIDAD EXTRAORDINARIA\n\nPremios/reconocimientos: {{premios_o_reconocimientos_recibidos}}\nMembresías: {{membresías_en_asociaciones_selectas}}\nPublicaciones: {{publicaciones_o_contribuciones_al_campo}}\nSalario elevado: {{evidencia_de_salario_elevado}}\nParticipación como juez: {{participación_como_juez_del_trabajo_de_otros}}\nContribuciones originales: {{contribuciones_originales_significativas}}",
                "itinerary": "ITINERARIO DE ACTIVIDADES\n\n{{itinerario_de_actividades_propuestas}}",
                "conclusion": "Con base en las calificaciones y evidencias presentadas, se solicita la aprobación de esta petición O-1.\n\nFirma: ____________________\nFecha: ____________"
            }'
            ;;
    esac
    
    generate_template "$template_id" "$template_name" "$description" "$questions" "$sections"
done

# 8. Documentos de apoyo y prueba de dificultades extremas
for i in {141..150}; do
    case $((i % 2)) in
        0)
            template_id="extreme_hardship_${i}"
            template_name="Declaración de Dificultades Extremas"
            description="Declaración detallada de dificultades extremas para exenciones"
            questions='[
                "Nombre del familiar ciudadano/residente",
                "Relación con el solicitante",
                "Edad del familiar",
                "Condiciones médicas del familiar",
                "Tratamientos médicos actuales",
                "Médicos o especialistas que lo atienden",
                "Situación financiera actual",
                "Dependencia financiera",
                "Condiciones en el país de origen",
                "Idiomas que habla el familiar",
                "Vínculos familiares en EE.UU.",
                "Vínculos familiares en el país de origen",
                "Impacto emocional de la separación",
                "Impacto en la educación/desarrollo de los hijos"
            ]'
            sections='{
                "header": "DECLARACIÓN DE DIFICULTADES EXTREMAS",
                "qualifying_relative": "INFORMACIÓN DEL FAMILIAR CALIFICADO\n\nNombre: {{nombre_del_familiar_ciudadano/residente}}\nRelación: {{relación_con_el_solicitante}}\nEdad: {{edad_del_familiar}}",
                "medical_hardship": "DIFICULTADES MÉDICAS\n\nCondiciones médicas: {{condiciones_médicas_del_familiar}}\nTratamientos actuales: {{tratamientos_médicos_actuales}}\nMédicos/especialistas: {{médicos_o_especialistas_que_lo_atienden}}",
                "financial_hardship": "DIFICULTADES FINANCIERAS\n\nSituación actual: {{situación_financiera_actual}}\nDependencia financiera: {{dependencia_financiera}}",
                "country_conditions": "CONDICIONES EN EL PAÍS DE ORIGEN\n\n{{condiciones_en_el_país_de_origen}}\nIdiomas: {{idiomas_que_habla_el_familiar}}",
                "family_ties": "VÍNCULOS FAMILIARES\n\nEn EE.UU.: {{vínculos_familiares_en_ee.uu.}}\nEn país de origen: {{vínculos_familiares_en_el_país_de_origen}}",
                "emotional_impact": "IMPACTO EMOCIONAL\n\nSeparación: {{impacto_emocional_de_la_separación}}\nImpacto en hijos/familia: {{impacto_en_la_educación/desarrollo_de_los_hijos}}",
                "declaration": "Declaro bajo pena de perjurio que la información proporcionada es verdadera y correcta.\n\nFirma: ____________________\nFecha: ____________"
            }'
            ;;
        1)
            template_id="supporting_letter_${i}"
            template_name="Carta de Apoyo"
            description="Carta de apoyo de familiar, amigo o empleador"
            questions='[
                "Nombre del remitente",
                "Dirección del remitente",
                "Relación con el solicitante",
                "Tiempo que conoce al solicitante",
                "Nombre del solicitante",
                "Carácter moral del solicitante",
                "Contribuciones a la familia/comunidad",
                "Circunstancias específicas a destacar",
                "Impacto de la deportación/denegación",
                "Estatus migratorio del remitente",
                "Ocupación del remitente"
            ]'
            sections='{
                "header": "CARTA DE APOYO",
                "date_address": "Fecha: [FECHA]\n\nA quien corresponda:",
                "introduction": "Mi nombre es {{nombre_del_remitente}} y soy {{relación_con_el_solicitante}} de {{nombre_del_solicitante}}. Soy {{estatus_migratorio_del_remitente}} y trabajo como {{ocupación_del_remitente}}. Conozco a {{nombre_del_solicitante}} desde hace {{tiempo_que_conoce_al_solicitante}}.",
                "character": "CARÁCTER MORAL\n\n{{carácter_moral_del_solicitante}}",
                "contributions": "CONTRIBUCIONES\n\n{{contribuciones_a_la_familia/comunidad}}",
                "circumstances": "CIRCUNSTANCIAS ESPECÍFICAS\n\n{{circunstancias_específicas_a_destacar}}",
                "impact": "IMPACTO\n\n{{impacto_de_la_deportación/denegación}}",
                "closing": "Por las razones mencionadas, le solicito respetuosamente que considere favorablemente el caso de {{nombre_del_solicitante}}.\n\nAtentamente,\n\n{{nombre_del_remitente}}\n{{dirección_del_remitente}}"
            }'
            ;;
    esac
    
    generate_template "$template_id" "$template_name" "$description" "$questions" "$sections"
done

echo "Se han generado 150 plantillas de documentos legales para inmigración."
echo "Las plantillas están disponibles en el directorio: document_service/templates"
