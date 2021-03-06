<?xml version="1.0" encoding="UTF-8"?>
<!-- This file is part of the SPFE Open Toolkit. See the accompanying license.txt file for applicable licenses.-->
<!-- (c) Copyright Analecta Communications Inc. 2012 All Rights Reserved. -->
<xsl:stylesheet version="2.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
				xmlns:date="http://exslt.org/dates-and-times" 
				xmlns:sf="http://spfeopentoolkit.org/spfe-ot/1.0/functions" 
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
				xmlns="http://www.w3.org/1999/xhtml" 
				xmlns:xs="http://www.w3.org/2001/XMLSchema"
				xmlns:config="http://spfeopentoolkit.org/spfe-ot/1.0/schemas/spfe-config"
				exclude-result-prefixes="#all">
	<xsl:import href="http://spfeopentoolkit.org/spfe-ot/1.0/scripts/common/utility-functions.xsl"/>
	<xsl:output method="xml" indent="yes"/>
	
	<xsl:variable name="config" as="element(config:spfe)">
		<xsl:sequence select="/config:spfe"/>
	</xsl:variable>
	
	<xsl:param name="toc-files"/>
	<xsl:variable name="unsorted-toc" >
		<xsl:variable name="temp-tocs">
			<xsl:for-each select="tokenize(translate($toc-files, '\', '/'), $config/config:dir-separator)">
				<xsl:variable name="toc-file" select="concat('file:///', normalize-space(.))"/>
				<xsl:call-template name="info">
					<xsl:with-param name="message" select="'Loading toc file:', $toc-file "/>
				</xsl:call-template>
				<xsl:sequence select="document($toc-file)"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="count(distinct-values($temp-tocs/toc/@topic-set-id)) lt count($temp-tocs/toc)">
			<xsl:call-template name="error">
				<xsl:with-param name="message">
					<xsl:text>Duplicate TOCs detected.&#x000A; There appears to be more than one TOC in scope for the same topics set. Topic set IDs encountered include:&#x000A;</xsl:text>
					<xsl:for-each select="$temp-tocs/toc">
						<xsl:value-of select="@topic-set-id,'&#x000A;'"/>
					</xsl:for-each>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:if>
		<xsl:sequence select="$temp-tocs"/>
	</xsl:variable>
	
	<xsl:variable name="toc">
		<xsl:choose>
			<xsl:when test="normalize-space($config/config:doc-set/config:topic-set-type-order)">
				<xsl:variable name="topic-set-type-order" select="tokenize($config/config:doc-set/config:topic-set-type-order, ',\s*')"/>
				
				<!-- Make sure there is an entry on the topic set type order list for every topic set type. -->
				<xsl:variable name="topic-set-types-found" select="distinct-values($unsorted-toc/toc/@topic-set-type)"/>
				
				<!-- Make sure all the topic set types appear on the topic type order list -->
				<xsl:call-template name="info">
					<xsl:with-param name="message">
						<xsl:text>Ordering the TOC acording the the topic set type list:</xsl:text>
						<xsl:value-of select="$config/config:doc-set/config:topic-set-type-order"/>
					</xsl:with-param>
				</xsl:call-template>				
				
				<xsl:if test="count($topic-set-types-found[not(.=$topic-set-type-order)])">
					<xsl:call-template name="error">
						<xsl:with-param name="message" select="'Topic type(s) missing from topic type order list: ', string-join($topic-set-types-found[not(.=$topic-set-type-order)], ', ')"/>
					</xsl:call-template>
				</xsl:if>

				<xsl:for-each select="$topic-set-type-order">
					<xsl:variable name="this-topic-set-type" select="."/>
					<xsl:for-each select="$unsorted-toc/toc[@topic-set-type eq $this-topic-set-type]">
						<xsl:sequence select="."/>
					</xsl:for-each>
				</xsl:for-each>

			</xsl:when>
			<xsl:when test="$config/config:doc-set/config:topic-sets">
				<xsl:call-template name="warning">
					<xsl:with-param name="message">
						<!-- FIXME: Should test for the two conditions mentioned below. -->
						<xsl:text>Topic set type order not specified. TOC will be in the order topic sets are listed in the /spfe/doc-set configuration setting. External TOC files will be ignored. If topic set IDs specified in doc set configuration do not match those defined in the topic set, that topic set will not be included.</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:for-each select="$config/config:doc-set/config:topic-sets/config:topic-set">
					<xsl:variable name="id" select="config:id"/>
					<xsl:sequence select="$unsorted-toc/toc[@topic-set-id eq $id]"/>
				</xsl:for-each>
				
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="warning">
					<xsl:with-param name="message">
						<xsl:text>Doc set configuration not found in config file. TOC will be in alphabetical order by topic-set-type.</xsl:text>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:for-each select="$unsorted-toc/toc">
					<xsl:sort select="@topic-set-type"/>
					<xsl:sequence select="."/>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	

	
	<xsl:variable name="draft" as="xs:boolean" select="$config/config:build-command='draft'"/>
	<xsl:param name="presentation-files"/>
	<xsl:variable name="presentation-dir" select="concat($config/config:build/config:build-directory, '/temp/presentation/')"/>
	
	<xsl:variable name="presentation">
		<xsl:for-each select="tokenize($presentation-files, $config/config:dir-separator)">
			<xsl:sequence select="doc(concat('file:///', $presentation-dir, .))"/>	
		</xsl:for-each>
	</xsl:variable>

	<xsl:variable name="title-string">
		<xsl:value-of select="$config/config:publication-info/config:title"/>
		<xsl:text>, </xsl:text>
		<xsl:value-of select="$config/config:publication-info/config:release"/>
	</xsl:variable>
	
	<xsl:strip-space elements="name"/>
	
	<xsl:function name="sf:html-header">
		<xsl:param name="title"/>
		<head>
			<title><xsl:value-of select="$title"/></title>
			<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
			<xsl:if test="$config/config:build-command eq 'draft'">
				<META HTTP-EQUIV="Cache-Control" CONTENT="no-cache"/>
				<META HTTP-EQUIV="Pragma" CONTENT="no-cache"/>
				<meta http-equiv="expires" content="FRI, 13 APR 1999 01:00:00 GMT"/> 
			</xsl:if>
			<xsl:for-each select="$config/config:format/config:html/config:css">
				<link rel="STYLESHEET" href="{.}" type="text/css" media="all"/>	
			</xsl:for-each>
			<xsl:for-each select="$config/config:format/config:html/config:java-script">
				<script type="text/javascript" src="{.}">&#160;</script>
			</xsl:for-each>
			
			<link rel="stylesheet" type="text/css" href="style/treeview/css/multi/tree.css">&#160;</link>
			<link rel="stylesheet" type="text/css" href="style/colorbox/colorbox.css" >&#160;</link>
			<script src="style/jquery-1.7.2.min.js">&#160;</script>
			<script src="style/colorbox/jquery.colorbox-min.js">&#160;</script>
			<script type="text/javascript" src="style/jstree/jquery.jstree.js">&#160;</script>
			<script>
			$(document).ready(function(){
				$(".inline").colorbox({inline:true, width:"50%"});
			});
			</script>
			
<!--			<script type="text/javascript" src="style/treeview/build/yahoo.js">&#160;</script>
			<script type="text/javascript" src="style/treeview/build/event.js">&#160;</script>
			<script type="text/javascript" src="style/treeview/build/treeview.js">&#160;</script>
			<script type="text/javascript" src="style/treeview/build/jktreeview.js">&#160;</script>
			<script type="text/javascript" src="style/folding.js">&#160;</script>-->
			
			<script type="text/javascript" class="source below">
$(function () {
	$("#toc")
		.jstree({         
		    "themes" : {
            "theme" : "default",
            "dots" : false,
            "icons" : false
        },
        "plugins" : ["themes","html_data"] })
		// 1) the loaded event fires as soon as data is parsed and inserted
		.bind("loaded.jstree", function (event, data) { })
		// 2) but if you are using the cookie plugin or the core `initially_open` option:
		.one("reopen.jstree", function (event, data) { })
		// 3) but if you are using the cookie plugin or the UI `initially_select` option:
		.one("reselect.jstree", function (event, data) { });
});
</script>
			
			<style type="text/css">
		
#wrap
{
	margin:0 auto;
}
#draft-header
{
	clear:both;
}

#toc-container
{
	float:left;
	width:20%;
	overflow:auto;
}
#main
{
	float:right;
	width:80%;

}

#footer
{
	clear:both;
}
				
ul.toc li {


}
ul.toc a, ul.toc span {

}
ul.toc a {

}
ul.toc ol {

}

			</style>
			
		</head>
	</xsl:function>
	
	<xsl:variable name="html-page-footer">
		<div id="footer">
			<br/>
			<br/>
			<hr/>
			<!-- Timestamp and options DRAFT notice -->
			<p>
				<xsl:value-of select="format-dateTime(current-dateTime(),'Generated on [Y0001]-[M01]-[D01] [H01]:[m01]:[s01].')"/>
				<xsl:if test="$config/config:build-command eq 'draft'">
					<span class="draft">
						<xsl:text>***** DRAFT ***** ***** DRAFT ***** ***** DRAFT *****</xsl:text>
					</span>
				</xsl:if>
			</p>
		</div>
	</xsl:variable>
	
	<xsl:template name="output-html-page">
		<xsl:param name="file-name" as="xs:string"/> 
		<xsl:param name="title"/>
		<xsl:param name="content"/>
		<!-- info -->
		<xsl:call-template name="info">
			<xsl:with-param name="message" select="concat('Formatting page: ', $file-name)"/>
		</xsl:call-template>

		<xsl:result-document href="file:///{$config/config:build/config:output-directory}/{$config/config:deployment/config:output-path}/{$file-name}" method="xml" indent="no" omit-xml-declaration="no" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
			<html xml:lang="en" lang="en">
				<xsl:sequence select="sf:html-header($title)"/>
				<xsl:choose>
					<xsl:when test="$content/*:frameset">
						<xsl:sequence select="$content"/>
					</xsl:when>
					<xsl:otherwise>
						<body>
							<xsl:sequence select="$content"/>
							<xsl:sequence select="$html-page-footer"/>
						</body>
					</xsl:otherwise>
				</xsl:choose>
			</html>
		</xsl:result-document>
	</xsl:template>
		

	<xsl:template name="main">
		<xsl:call-template name="info">
			<xsl:with-param name="message">
				<xsl:choose>
					<xsl:when test="$config/config:build-command eq'draft'">
						<xsl:text>Creating a draft format because build command was "draft".</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>Creating a final format.</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:apply-templates select="$presentation/web/page"/>
	</xsl:template>
	
	<xsl:template match="page">
		<xsl:call-template name="output-html-page">
			<xsl:with-param name="file-name" select="concat(normalize-space(@name), '.html')"/> 
			<xsl:with-param name="title" select="title"/>
			<xsl:with-param name="content">
				<xsl:if test="$draft">
					<div id="draft-header">
						<p class="status-{translate(@status,' ', '_')}">
							<b class="cBold">Topic Name: </b>
							<xsl:value-of select="@name"/>
							<b class="cBold"> Topic Status: </b>
							<xsl:value-of select="@status"/>
						</p>
						<xsl:if test=".//review-note">
							<p>
								<b>Index of review notes: </b> 
								<xsl:for-each select=".//review-note">
									<a href="#review-note:{position()}">
										[<xsl:value-of select="position()"/>]
									</a>
									<xsl:text> </xsl:text>
								</xsl:for-each>
							</p>
						</xsl:if>
						<xsl:if test=".//author-note">
							<p>
								<b>Index of author notes: </b> 
								<xsl:for-each select=".//author-note">
									<a href="#author-note:{position()}">
										[<xsl:value-of select="position()"/>]
									</a>
									<xsl:text> </xsl:text>
								</xsl:for-each>
							</p>
						</xsl:if>
						<hr/>
					</div>
				</xsl:if>
				<div id="toc-container" >
					<div id="toc">
						<ul>
							<xsl:apply-templates select="$toc"/>
						</ul>
					</div>
				</div>
				
				<div id="main">
					<xsl:apply-templates/>
				</div>
				
				<xsl:call-template name="output-xref-sets"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	
	<xsl:template match="section">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- TABLE -->
	
	<xsl:template match="table">
		<!-- Move the title outside the table -->
		<xsl:if test="title">
			<h4>
				<xsl:text>Table&#160;</xsl:text>
				<xsl:value-of select="count(ancestor::page//table/title intersect preceding::table/title)+1"/>
				<xsl:text>&#160;&#160;&#160;</xsl:text>
				<xsl:value-of select="title"/>
			</h4>
		</xsl:if>
		<table>
			<xsl:attribute name="class" select="if (@hint) then @hint else 'BA_basic'"/>
			<xsl:apply-templates>
				<xsl:with-param name="column-width-weights" select="@column-width-weights" tunnel="yes"/>
			</xsl:apply-templates>
		</table>
	</xsl:template>
	
	<xsl:template match="tr">
		<tr><xsl:apply-templates/></tr>
	</xsl:template>
	
	<xsl:template match="th">
		<th align="left">
			<xsl:call-template name="get-column-width"/>
			<xsl:apply-templates/>	
		</th>
	</xsl:template>
	
	<xsl:template match="td">
		<td align="left" valign="top">
			<xsl:call-template name="get-column-width"/>
			<xsl:apply-templates/>	
		</td>
	</xsl:template>
	
	<xsl:template name="get-column-width">
		<xsl:param name="column-width-weights" tunnel="yes"/>
		<xsl:if test="$column-width-weights">
			<xsl:variable name="weights" as="xs:integer*">
				<xsl:for-each select="tokenize(normalize-space($column-width-weights), ' ' )">
					<xsl:value-of select="number(.)"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="total-weights" select="sum($weights)" />
			<xsl:variable name="col-num" select="count(preceding-sibling::*)+1"/>
			<xsl:attribute name="style">
				<xsl:text>width:</xsl:text>
				<xsl:value-of select="$weights[$col-num] div $total-weights * 100" />
				<xsl:text>%</xsl:text>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>
	
	<!-- FIG -->
	<xsl:template match="fig">
		<xsl:if test="title">
			<h4>
				<xsl:text>Figure&#160;</xsl:text>
				<xsl:value-of select="count(ancestor::page//fig/title intersect preceding::fig/title)+1"/>
				<xsl:text>&#160;&#160;&#160;</xsl:text>
				<xsl:value-of select="title"/>
			</h4>
		</xsl:if>
		<img src="{@href}" alt="{title}" title="{title}"/>
		<xsl:apply-templates/>
	</xsl:template>

	<!-- TITLES -->

	<xsl:template match="page/title">
		<h1><xsl:apply-templates/></h1>
		<!-- page toc -->
		<xsl:if test="count(../section/title) gt 1">
			<ul>
				<xsl:for-each select="../section/title">
					<li>
						<a href="#{sf:title2anchor(normalize-space(.))}">
							<xsl:value-of select="."/>
						</a>
					</li>
				</xsl:for-each>
			</ul>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="section/title">
		<h2><xsl:apply-templates/></h2>
	</xsl:template>
	
	<xsl:template match="procedure/title">
		<h3><xsl:apply-templates/></h3>
	</xsl:template>
	
 
	<xsl:template match="subhead">
		<h3>
			<xsl:apply-templates/>
		</h3>
	</xsl:template>
	
	<xsl:template match="fold/title">
		<h3>
			<xsl:apply-templates/>
		</h3>
	</xsl:template>
	
	<xsl:template match="step/title">
		<h4>
			<xsl:text>Step&#160;</xsl:text>
			<xsl:value-of select="count(../preceding-sibling::*:step)+1"/>
			<xsl:text>:&#160;</xsl:text>
			<xsl:apply-templates/>
		</h4>
	</xsl:template>
	
	<xsl:template match="code-sample">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="code-sample/title">
		<h4>
				<xsl:text>Example&#160;</xsl:text>
				<xsl:value-of select="count(ancestor::page//code-sample/title intersect preceding::code-sample/title)+1"/>
				<xsl:text>&#160;&#160;&#160;</xsl:text>
			<xsl:apply-templates/>
		</h4>
	</xsl:template>
	
	<!-- FIXME: Procedures and steps??? -->
	
	<!-- suppress fig and table titles because they are handled in  the parent -->
	<xsl:template match="table/title"/>
	
	<xsl:template match="fig/title"/>
	
	
	<!-- PARAGRAPHS -->
	
	<xsl:template match="p">
		<p>
			<xsl:if test="@hint">
				<xsl:attribute name="class" select="@hint"/>
			</xsl:if>
			<xsl:if test="$draft">
				<xsl:variable name="my-page" select="ancestor::page"/>
				<span class="draft">
					<b class="cBold">
						<xsl:value-of select="count(preceding::p[ancestor::page is $my-page])+1"/>
					</b>
				</span>
			</xsl:if>
			<xsl:apply-templates/>
		</p>
	</xsl:template>
	
	<xsl:template match="codeblock">
		<pre><xsl:apply-templates/></pre>
	</xsl:template>
	
	<xsl:template match="codeblock/text()">
		<!--filter out the zero-width NBS used to preserve formatting -->
		<xsl:value-of select="replace(., '&#8288;', '')"/>
	</xsl:template>

	<xsl:template match="labeled-item">
		<xsl:if test="anchor">
			<a name="{anchor/@name}">&#8194;</a>
		</xsl:if>
		<dl><xsl:apply-templates/></dl>
	</xsl:template>
	
	<xsl:template match="label">
		<dt>
			<xsl:choose>
				<xsl:when test="child::*">
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<b class="cBold"><xsl:apply-templates/></b>
				</xsl:otherwise>
			</xsl:choose>
		</dt>
	</xsl:template>
	
	<xsl:template match="item">
		<dd><xsl:apply-templates/>	</dd>
	</xsl:template>
	
	<xsl:template match="note">
		<div align="left">
			<table class="N1_note" border="0" cellpadding="0" cellspacing="6">
				<tr align="left" valign="top">
					<td/>
					<td class="N1_note_content">
						<xsl:apply-templates/>
					</td>
				</tr>
				<tr align="left" valign="top">
					<td>&#160;</td>
					<td>&#160;</td>
				</tr>
			</table>
		</div>
	</xsl:template>
	
	<xsl:template match="note/p[1]">
		<p class="pzzBodyNote">
			<b class="cBold">NOTE: </b>
			<xsl:apply-templates/>
		</p>
	</xsl:template>		
	
	<xsl:template match="caution/p[1]">
		<p class="pzzBodyNote">
			<b class="cBold">CAUTION: </b>
			<xsl:apply-templates/>
		</p>
	</xsl:template>	
	
	<xsl:template match="warning/p[1]">
		<p class="pzzBodyNote">
			<b class="cBold">WARNING: </b>
			<xsl:apply-templates/>
		</p>
	</xsl:template>						
	
	<xsl:template match="caution">
		<div align="left">
			<table class="C1_caution" border="0" cellpadding="0" cellspacing="6">
				<tr align="left" valign="top">
					<td/>
					<td class="C1_caution_content">
						<xsl:apply-templates/>
					</td>
				</tr>
				<tr align="left" valign="top">
					<td>&#160;</td>
					<td>&#160;</td>
				</tr>
			</table>
		</div>
	</xsl:template>
	
	<xsl:template match="anchor">
		<!-- insert non-breaking space to work round firefox rendering bug with empty elements-->
		<a name="{@name}">&#8194;</a>
	</xsl:template>
	
	<xsl:template match="warning">
		<div align="left">
			<table class="W1_warning" border="0" cellpadding="0" cellspacing="6">
				<tr align="left" valign="top">
					<td/>
					<td class="W1_warning_content">
						<xsl:apply-templates/>
					</td>
				</tr>
				<tr align="left" valign="top">
					<td>&#160;</td>
					<td>&#160;</td>
				</tr>
			</table>
		</div>
	</xsl:template>

	<!--- ANCHORS -->

	<!-- anchors have to be pulled outside labled items in XHTML -->
	<xsl:template match="labeled-item/anchor"/>

	
	<!-- LISTS -->

	<xsl:template match="ul|ol|li">
		<!-- Note that we can't use xsl:copy here as that creates a
	     copy in the same namespace as the source. Here we need 
			 to create an element of the same name but in the XHTML 
			 namespace. xsl:element creates elements in the default
			 namespace declared in xsl:stylesheet. -->
		<xsl:element name="{name()}">
			<xsl:if test="@hint">
				<xsl:attribute name="class" select="@hint"/>
			</xsl:if>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	

	<xsl:template match="author-note ">
		<xsl:variable name="my-page" select="ancestor::page"/>
		<xsl:variable name="my-position" select="count(preceding::author-note[ancestor::page is $my-page])+1"/>
		<xsl:if test="$draft">
			<a name="author-note:{$my-position}">&#8194;</a>
			<span class="author-note">
				<xsl:value-of select="$my-position"/> 
				<xsl:text> - </xsl:text>
				<xsl:apply-templates/>
			</span>
		</xsl:if>
	</xsl:template>
	
		<xsl:template match="review-note">
		<xsl:variable name="my-page" select="ancestor::page"/>
		<xsl:variable name="my-position" select="count(preceding::review-note[ancestor::page is $my-page])+1"/>
			<xsl:if test="$draft">
			<a name="review-note:{$my-position}">&#8194;</a>
			<span class="review-note">
				<xsl:value-of select="$my-position"/> 
				<xsl:text> - </xsl:text>
				<xsl:apply-templates/>
			</span>
		</xsl:if>
	</xsl:template>

	<!-- LINKS -->
	
	<xsl:template match="xref">
		<xsl:variable name="class" select="if (@class) then @class else 'default'"/>
		<xsl:variable name="target" select="@target"/>
		<a href ="{$target}" class="{$class}" title="{if(ancestor::table[@hint='context']) then 'See also - ' else ''}{@title}">
      <xsl:if test="@onclick">
        <xsl:attribute name="onClick" select="@onclick"/>
      </xsl:if>
			<xsl:apply-templates/>
		</a>
	</xsl:template>
	
	<xsl:template match="xref[@hint='term']">
		<xsl:variable name="target" select="@target"/>
		<a class="gloss-fold" onclick="toggle_visibility('gloss-fold-{generate-id()}');" title="Definition of: {.}">
      <xsl:if test="@onclick">
        <xsl:attribute name="onClick" select="@onclick"/>
      </xsl:if>
      <xsl:value-of select="."/>
    </a>
		<span style="display: none;" class="fold" id="gloss-fold-{generate-id()}">			
			<span  style="display:block; font-weight:bold">Definition of: <xsl:value-of select="."/>
				<a style="float:right" class="fold" onclick="toggle_visibility('gloss-fold-{generate-id()}');">[x]</a>
			</span>
			<span  style="display:block;">
				<xsl:value-of select="@title"/>
			</span>
		</span>
	</xsl:template>
	
	<xsl:template match="fold">
		<xsl:variable name="id" select="@id"/>
		<div style="display: none;" class="fold" id="text-fold-{$id}">			
			<span  style="display:block; font-weight:bold">More on: <xsl:value-of select="@reference-text"/>
				<a style="float:right" class="fold" onclick="toggle_visibility('text-fold-{$id}');">[x]</a>
			</span>
			<xsl:apply-templates/>
		</div>
	</xsl:template>
	
	<xsl:template match="fold-toggle">
			<a class="fold" onclick="toggle_visibility('text-fold-{@id}');" title="more..."><xsl:apply-templates/></a>
	</xsl:template>
			
	<xsl:template match="xref-set">
		<!-- FIXME: This should have a title, but it interferes with colorbox. Fix? Alternative? -->
		<!-- title="{if(ancestor::table[@hint='context']) then 'See also - ' else ''}{string-join(xref/@title, '; ')}" -->
		<a class='inline' href="#{generate-id()}" >
			<xsl:value-of select="content"/>
		</a>
	</xsl:template>
	
	<xsl:template name="output-xref-sets">
		<div style='display:none'>
		<xsl:for-each select="//xref-set">
		
			<div id='{generate-id()}' style='padding:10px; background:#fff;'>
				
				<xsl:variable name="class" select="if (xref/@class = 'gloss') then 'gloss' else 'default'"/>
				<h4>Resources on "<xsl:value-of select="content"/>"</h4>
				
						

				<div  style="display:list; list-style-type:disc; list-style-position: inside; ">
					<xsl:for-each select="xref">
						<span style="display:list-item">
							<xsl:value-of select="@topic-type"/>
							<xsl:text>: </xsl:text>
							<a href="{@target}" class="default" >
								<xsl:if test="@onclick">
									<xsl:attribute name="onClick" select="@onclick"/>
								</xsl:if>
								<xsl:value-of select="@topic-title"/>
							</a><!--
							<xsl:text> (</xsl:text>
							<xsl:value-of select="@topic-product"/>
							<xsl:text>)</xsl:text>-->
						</span>
					</xsl:for-each>
				</div>
		
			</div>
		</xsl:for-each>
		</div>
		
		
	</xsl:template>

	<xsl:template match="xlink">
		<a href="{@href}" target="_blank">
			<xsl:apply-templates/>
		</a>
	</xsl:template>

	<xsl:template match="tool-tip">
		<xsl:variable name="class" select="if (@class) then @class else 'default'"/>
		<xsl:element name="a">
			<xsl:attribute name="class" select="$class"/>
			<xsl:attribute name="title" select="@title"/>
			<xsl:apply-templates/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="cross-ref">
		<xsl:variable name="target" select="@target"/>
		<xsl:variable name="type" select="@type"/>
		<xsl:choose>
	
			<xsl:when test="$type='procedure'">
				<xsl:variable name="target-procedure" select="ancestor::page//procedure[@id=$target]"/>
				<a href="#procedure:{$target-procedure/@id}">
					<i>
						<xsl:value-of select="$target-procedure/title"/>
					</i>
				</a>
			</xsl:when>
			
			<xsl:when test="$type='step'">
				<xsl:variable name="target-step" select="ancestor::page//step[@id=$target]"/>
				<a href="#step:{$target-step/id}">
					<xsl:value-of select="concat('Step ', count(//step[@id=current()/$target]/preceding-sibling::step)+1)"/>
					<xsl:value-of select="//step[@id=current()/@id-ref]/title"/>
				</a>
			</xsl:when>
			
			<xsl:when test="$type='fig'">
				<xsl:variable name="target-fig" select="ancestor::page//fig[@id=$target]"/>
				<a href="#fig:{$target}">
					<xsl:text>Figure&#160;</xsl:text>
						<xsl:value-of select="count(ancestor::page//fig/title intersect $target-fig/preceding::fig/title)+1"/>
				</a>
			</xsl:when>
			
			<xsl:when test="$type='table'">
				<xsl:variable name="target-table" select="ancestor::page//table[@id=$target]"/>
				<a href="#table:{$target}">
					<!-- Insert a zero-width-non-breaking-space so indenter recognizes 
					this as a text node and does not indent it (which would add spurious
					white space to output -->
					<xsl:text>Table&#160;</xsl:text>
						<xsl:value-of select="count(ancestor::page//table/title intersect $target-table/preceding::table/title)+1"/>
				</a>
			</xsl:when>
			
			<xsl:when test="$type='code-sample'">
				<xsl:variable name="target-sample" select="ancestor::page//code-sample[@id=$target]"/>
				<a href="#code-sample:{$target}">
					<!-- Insert a zero-width-non-breaking-space so indenter recognizes 
					this as a text node and does not indent it (which would add spurious
					white space to output -->
					<xsl:text>Example&#160;</xsl:text>
						<xsl:value-of select="count(ancestor::page//code-sample/title intersect $target-sample/preceding::code-sample/title)+1"/>
				</a>
			
			</xsl:when>

			<xsl:otherwise>
				<xsl:call-template name="error">
					<xsl:with-param name="message">Unknown cross-reference type "<xsl:value-of select="$type"/>.</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- CHARACTERS -->
	
	<xsl:template match="name|value|code|gui-label|bold">
		<b class="cBold"><xsl:apply-templates/></b>
	</xsl:template>

	<xsl:template match="placeholder|italic">
		<em><xsl:apply-templates/></em>
	</xsl:template>
	
	
	
	<xsl:template match="toc">
		<xsl:variable name="branch" select="generate-id()"/>
		<xsl:variable name="toc-id" select="concat('toc', $branch)"/>
	
		<xsl:variable name="relative-path">
			<xsl:for-each select="tokenize($config/config:deployment/config:output-path, '/')">
				<xsl:text>../</xsl:text>
			</xsl:for-each>
			<xsl:if test="normalize-space(@deployment-relative-path)">
				<xsl:value-of select="normalize-space(@deployment-relative-path)"/>
				<xsl:text>/</xsl:text>
			</xsl:if>
		</xsl:variable>
		
		<li id="{generate-id()}" class="jstree-open">
			<a href="{if (@index) then concat($relative-path, @index, '.html') else '#'}">
				<xsl:value-of select="@title"/>
			</a>
			<xsl:if test="node">
				<ul>
					<xsl:apply-templates>
						<xsl:with-param name="relative-path" select="$relative-path"/>
					</xsl:apply-templates>
				</ul>
			</xsl:if>
		</li>
		

	</xsl:template>
	
	<xsl:template match="node">
		<xsl:param name="relative-path"/>
		
		<xsl:variable name="href">
			<xsl:choose>
				<!-- link to internal anchor of parent node page -->
				<xsl:when test="contains(@id, '#')">
					<xsl:value-of select="concat($relative-path, substring-before(@id, '#'),
						'.html#',
						substring-after(@id, '#'))"/>
				</xsl:when>
				
				<xsl:when test="@id">
					<xsl:value-of select="concat($relative-path, @id, '.html')"/>
				</xsl:when>
				
				<xsl:when test="@group-id">
					<xsl:value-of select="concat($relative-path, sf:title2anchor(@group-id), '.html')"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		
			<xsl:choose>
				<xsl:when test="normalize-space($href) ne '' and node">
					<li id="{generate-id()}" class="jstree-open">
						<a href="{$href}"><xsl:value-of select="@name"/></a>
						<ul>
							<xsl:apply-templates>
								<xsl:with-param name="relative-path" select="$relative-path"/>
							</xsl:apply-templates>
						</ul>
					</li>
				</xsl:when>
				
				<xsl:when test="normalize-space($href)">
					<li id="{generate-id()}" class="jstree-open">
						<a href="{$href}"><xsl:value-of select="@name"/></a>
					</li>
				</xsl:when>
				
				<xsl:when test="node">
					<li id="{generate-id()}" class="jstree-open">
						<a href="#"><xsl:value-of select="@name"/></a>
						<ul>
							<xsl:apply-templates>
								<xsl:with-param name="relative-path" select="$relative-path"/>
							</xsl:apply-templates>
						</ul>
					</li>
				</xsl:when>
				<xsl:otherwise>
					<!-- ERROR? -->
				</xsl:otherwise>
			</xsl:choose>
	</xsl:template>
	
	
	
	
	
	<xsl:template match="procedure">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="step">
		<xsl:apply-templates/>
	</xsl:template>

	
</xsl:stylesheet>
