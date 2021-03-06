<?xml version="1.0" encoding="UTF-8"?>
<!-- This file is part of the SPFE Open Toolkit. See the accompanying license.txt file for applicable licenses.-->
<!-- (c) Copyright Analecta Communications Inc. 2012 All Rights Reserved. -->
<!-- ===================================================
	synthesize-authored-topics.xsl
	
	Reads the collection of topic files and text object files
	for the topic set, processes the topic element, and hands 
	the rest of the processing off to the inculded stylesheets.

	=======================================================-->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:sf="http://spfeopentoolkit.org/spfe-ot/1.0/functions"
xmlns:config="http://spfeopentoolkit.org/spfe-ot/1.0/schemas/spfe-config"
xmlns:ss="http://spfeopentoolkit.org/spfe-ot/1.0/schemas/synthesis"
xmlns:gt="http://spfeopentoolkit.org/spfe-docs/schemas/authoring/generic-topic"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
exclude-result-prefixes="#all">
	
	<xsl:variable name="topic-type-alias-list" select="$config/config:topic-type-aliases" as="element(config:topic-type-aliases)"/>
	
	
	<xsl:function name="sf:name-from-uri">
		<xsl:param name="uri"/>
		<xsl:value-of select="substring-before(tokenize($uri, '/')[count(tokenize($uri, '/'))], '.xml')"/>
	</xsl:function>
	
	<xsl:template match="gt:generic-topic">
		<xsl:variable name="conditions" select="@if"/>
		<xsl:variable name="topic-type" select="tokenize(normalize-space(@xsi:schemaLocation), '\s')[1]"/>
		
		<xsl:variable name="topic-type-alias">
			<xsl:choose>
				<xsl:when test="$topic-type-alias-list/config:topic-type[config:id=$topic-type]">
					<xsl:value-of select="$topic-type-alias-list/config:topic-type[config:id=$topic-type]/config:alias"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="error">
						<xsl:with-param name="message">
							<xsl:text>No topic type alias found for topic type </xsl:text>
							<xsl:value-of select="$topic-type"/>
							<xsl:text>.</xsl:text>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:value-of select="$topic-type"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		
			<xsl:choose>
				<xsl:when test="sf:conditions-met($conditions, $condition-tokens)">
					<ss:topic 
						element-name="{name()}" 
						type="{namespace-uri()}" 
						topic-type-alias="{$topic-type-alias}"
						full-name="{gt:head/gt:uri}"
						local-name="{sf:name-from-uri(gt:head/gt:uri)}"
						title="{gt:body/gt:title}">
						<xsl:if test="gt:head/gt:virtual-type">
							<xsl:attribute name="virtual-type" select="gt:head/gt:virtual-type"/>
						</xsl:if>
						<xsl:copy>
							<xsl:copy-of select="@*"/>
							<xsl:call-template name="apply-topic-attributes"/>
							<xsl:apply-templates/>
						</xsl:copy>
					</ss:topic>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="info">
						<xsl:with-param name="message">
							<xsl:text>Suppressing topic </xsl:text>
							<xsl:value-of select="name"/>
							<xsl:text> because its conditions (</xsl:text>
							<xsl:value-of select="$conditions"/>
							<xsl:text>) do not match the conditions specified for the build ( </xsl:text>
							<xsl:value-of select="$condition-tokens"/>
							<xsl:text>).</xsl:text>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
	</xsl:template>
	

</xsl:stylesheet>

