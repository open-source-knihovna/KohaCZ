<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:marc="http://www.loc.gov/MARC21/slim"
  version="2.0">

 <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
 <xsl:strip-space elements="*"/>

 <xsl:template match="marc:controlfield[@tag=001]"/>
 <xsl:template match="marc:datafield[@tag=999]">
         <controlfield tag="001"><xsl:value-of select="marc:subfield[@code='c']" /></controlfield>
 </xsl:template>

 <xsl:template match="@* | node()">
 <xsl:copy>
 <xsl:apply-templates select="@* | node()"/>
 </xsl:copy>
  <xsl:for-each select="marc:datafield[@tag=993]">
    <datafield ind1=" " ind2=" " tag="996">
        <subfield code="b"><xsl:value-of select="marc:subfield[@code=1]"/></subfield>
        <xsl:if test="marc:subfield[@code='g']"><subfield code="h"><xsl:value-of select="marc:subfield[@code='g']"/></subfield></xsl:if>
        <xsl:choose>
            <xsl:when test="marc:subfield[@code='x'] and marc:subfield[@code='y']='PE'" >
                <subfield code="d"><xsl:value-of select="marc:subfield[@code='p']"/></subfield>
                <subfield code="i"><xsl:value-of select="substring-before(marc:subfield[@code='p'],'/')"/></subfield>
                <subfield code="y"><xsl:value-of select="substring-after(marc:subfield[@code='p'],'/')"/></subfield>
            </xsl:when>
            <xsl:when test="marc:subfield[@code=8]">
                <subfield code="d"><xsl:value-of select="marc:subfield[@code='8']"/></subfield>
                <xsl:choose>
                    <xsl:when test="contains(marc:subfield[@code='8'],'/')">
                        <subfield code="i"><xsl:value-of select="substring-before(marc:subfield[@code='8'],'/')"/></subfield>
                        <subfield code="y"><xsl:value-of select="substring-after(marc:subfield[@code='8'],'/')"/></subfield>
                    </xsl:when>
                    <xsl:otherwise>
                        <subfield code="i"><xsl:value-of select="marc:subfield[@code='8']"/></subfield>
                        <subfield code="y"><xsl:value-of select="substring-after(marc:subfield[@code='8'],'.')"/></subfield>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="marc:subfield[@code='y']='PE'">
                <subfield code="d"><xsl:value-of select="marc:subfield[@code='p']"/></subfield>
                <xsl:choose>
                    <xsl:when test="contains(marc:subfield[@code='p'],'/')">
                        <subfield code="i"><xsl:value-of select="substring-before(marc:subfield[@code='p'],'/')"/></subfield>
                        <subfield code="y"><xsl:value-of select="substring-after(marc:subfield[@code='p'],'/')"/></subfield>
                    </xsl:when>
                    <xsl:otherwise>
                        <subfield code="i"><xsl:value-of select="marc:subfield[@code='p']"/></subfield>
                        <subfield code="y"><xsl:value-of select="substring-after(substring-after(marc:subfield[@code='p'],'.'),'.')"/></subfield>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
        <subfield code="l"><xsl:choose>
            <xsl:when test="marc:subfield[@code='f']='PPM' or marc:subfield[@code='f']='PP'">PARNIK</xsl:when>
            <xsl:otherwise>CESKATREBOVA</xsl:otherwise>
        </xsl:choose></subfield>
        <subfield code="r"><xsl:choose>
            <xsl:when test="marc:subfield[@code='f']='PPM' or marc:subfield[@code='f']='M'">DETSKE</xsl:when>
            <xsl:when test="marc:subfield[@code='f']='T'">MLADEZ</xsl:when>
            <xsl:when test="marc:subfield[@code='f']='PRK'">PRIRUCNI</xsl:when>
            <xsl:otherwise>DOSPELE</xsl:otherwise>
        </xsl:choose></subfield>
        <subfield code="s"><xsl:choose>
            <xsl:when test="marc:subfield[@code='f']='ST' or marc:subfield[@code=7]>0">P</xsl:when>
            <xsl:otherwise>A</xsl:otherwise>
        </xsl:choose></subfield>
        <xsl:if test="marc:subfield[@code='e']"><subfield code="n"><xsl:value-of select="marc:subfield[@code='e']"/></subfield></xsl:if>
        <subfield code="a"><xsl:choose>
            <xsl:when test="marc:subfield[@code='f']='ST' or marc:subfield[@code=7]>0">99999</xsl:when>
            <xsl:when test="marc:subfield[@code='f']='SPBE' or marc:subfield[@code='f']='PP' or marc:subfield[@code='f']='PPM'">48</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
        </xsl:choose></subfield>
        <subfield code="w"><xsl:value-of select="marc:subfield[@code='9']"/></subfield>
    </datafield>
  </xsl:for-each>

 </xsl:template>

 <xsl:template match="marc:subfield[@code=9]"/>
 <xsl:template match="marc:datafield[@tag=942]"/>
 <xsl:template match="marc:datafield[@tag=955]"/>
 <xsl:template match="marc:datafield[@tag=993]"/>

</xsl:stylesheet>

