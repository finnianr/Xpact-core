<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE xsl:stylesheet [
<!ENTITY % selectors SYSTEM "db-selectors.mod">
%selectors;
]>
<!-- Reference to &db_infos; permitted because of %selectors; -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:msg="http://projects.gnome.org/yelp/gettext/"
                exclude-result-prefixes="db msg"
                version="1.0">

   <xsl:template name="db.title">
     <xsl:param name="node" select="."/>
     <xsl:param name="info" select="$node/&db_infos;"/>
   </xsl:template>


   <xsl:template name="db.titleabbrev">
     <xsl:param name="node" select="."/>
     <xsl:param name="info" select="$node/&db_infos;"/>
   </xsl:template>


</xsl:stylesheet>
