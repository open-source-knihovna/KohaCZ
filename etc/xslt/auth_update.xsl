<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  version="1.0">

 <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
 <xsl:strip-space elements="*"/>

 <xsl:template match="marc:controlfield[@tag=005]"/>

 <xsl:template match="@* | node()">
 <xsl:copy>
 <xsl:apply-templates select="@* | node()"/>
 </xsl:copy>
 </xsl:template>

 <xsl:template match="marc:datafield[@tag=995]">
        <controlfield tag="005" xmlns="http://www.loc.gov/MARC21/slim"><xsl:value-of select="marc:subfield[@code='a']" /></controlfield>
 </xsl:template>
</xsl:stylesheet>
