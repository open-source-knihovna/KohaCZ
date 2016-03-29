<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  version="1.0">

 <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
 <xsl:strip-space elements="*"/>

 <xsl:template match="marc:controlfield[@tag=001]"/>

 <xsl:template match="@* | node()">
 <xsl:copy>
 <xsl:apply-templates select="@* | node()"/>
 </xsl:copy>
 </xsl:template>

 <xsl:template match="marc:subfield[@code=9]"/>
 <xsl:template match="marc:datafield[@tag=942]"/>
 <xsl:template match="marc:datafield[@tag=955]"/>

 <xsl:template match="marc:datafield[@tag=999]">
        <controlfield tag="001" xmlns="http://www.loc.gov/MARC21/slim"><xsl:value-of select="marc:subfield[@code='c']" /></controlfield>
 </xsl:template>


</xsl:stylesheet>

