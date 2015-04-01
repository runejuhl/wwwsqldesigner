<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>

  <xsl:template name="replace-substring">
    <xsl:param name="value" />
    <xsl:param name="from" />
    <xsl:param name="to" />
    <xsl:choose>
      <xsl:when test="contains($value,$from)">
        <xsl:value-of select="substring-before($value,$from)" />
        <xsl:value-of select="$to" />
        <xsl:call-template name="replace-substring">
          <xsl:with-param name="value" select="substring-after($value,$from)" />
          <xsl:with-param name="from" select="$from" />
          <xsl:with-param name="to" select="$to" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="/sql">

    <!-- tables -->
    <xsl:for-each select="table">
      <xsl:text>CREATE TABLE </xsl:text>
      <xsl:value-of select="@name" />
      <xsl:text> (
  </xsl:text>
      <xsl:for-each select="row">
        <xsl:value-of select="@name" />
        <xsl:text> </xsl:text>

        <xsl:choose>
          <xsl:when test="@autoincrement = 1">
            <!-- use postgresql SERIAL shortcut for columns marked as
                 auto-increment. this creates integer column,
                 corresponding sequence, and default expression for the
                 column with nextval(). see:
                 http://www.postgresql.org/docs/current/static/datatype-numeric.html#DATATYPE-SERIAL
            -->
            <xsl:text> SERIAL</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="datatype" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>

        <xsl:if test="@null = 0">
          <xsl:if test="not(datatype = 'SERIAL')">
            <xsl:text>NOT NULL </xsl:text>
          </xsl:if>
        </xsl:if>

        <xsl:if test="default">
          <xsl:choose>
            <xsl:when test='default ="&apos;current_timestamp&apos;"'>
              <xsl:text>DEFAULT current_timestamp </xsl:text>
            </xsl:when>
            <xsl:when test=" default != 'NULL' ">
              <xsl:text>DEFAULT </xsl:text>
              <xsl:value-of select="default" />
              <xsl:text> </xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:if>

        <xsl:if test="comment">
          <xsl:text>/* </xsl:text>
          <xsl:value-of select="comment"/>
          <xsl:text> */</xsl:text>
        </xsl:if>

        <xsl:if test="not (position()=last())">
          <xsl:text>,
  </xsl:text>
        </xsl:if>
      </xsl:for-each>

      <!-- keys -->
      <xsl:for-each select="key">
        <xsl:if test="@type ='PRIMARY' or @type = 'UNIQUE'">
          <xsl:text>,
  </xsl:text>
          <xsl:if test="@type = 'PRIMARY'">
            <xsl:text>PRIMARY KEY (</xsl:text>
          </xsl:if>

          <xsl:if test="@type = 'UNIQUE'">
            <xsl:text>CONSTRAINT </xsl:text>
            <xsl:value-of select="@name"/>
            <xsl:text> UNIQUE (</xsl:text>
          </xsl:if>

          <xsl:for-each select="part">
            <xsl:value-of select="." />
            <xsl:if test="not (position() = last())">
              <xsl:text>, </xsl:text>
            </xsl:if>
          </xsl:for-each>
          <xsl:text>)</xsl:text>
        </xsl:if>

      </xsl:for-each>

      <xsl:text>
);
</xsl:text>

      <xsl:if test="comment">
        <xsl:text>COMMENT ON TABLE </xsl:text>
        <xsl:value-of select="@name"/>
        <xsl:text> IS '</xsl:text>
        <xsl:call-template name="replace-substring">
          <xsl:with-param name="value" select="comment" />
          <xsl:with-param name="from" select='"&apos;"' />
          <xsl:with-param name="to" select='"&apos;&apos;"' />
        </xsl:call-template>
        <xsl:text>';
</xsl:text>
      </xsl:if>

      <!-- column comments -->
      <xsl:for-each select="row">
        <xsl:if test="comment">
          <xsl:text>COMMENT ON COLUMN </xsl:text>
          <xsl:value-of select="../@name"/>
          <xsl:text>.</xsl:text>
          <xsl:value-of select="@name"/>
          <xsl:text> IS '</xsl:text>
          <xsl:call-template name="replace-substring">
            <xsl:with-param name="value" select="comment" />
            <xsl:with-param name="from" select='"&apos;"' />
            <xsl:with-param name="to" select='"&apos;&apos;"' />
          </xsl:call-template>
          <xsl:text>';
</xsl:text>
        </xsl:if>
      </xsl:for-each>

      <!-- indexes -->
      <xsl:for-each select="key">
        <xsl:if test="@type = 'INDEX'">
          <xsl:text>CREATE INDEX </xsl:text>
          <xsl:if test="not(normalize-space(@name) = '')">
            <xsl:value-of select="@name"/>
            <xsl:text> </xsl:text>
          </xsl:if>
          <xsl:text>ON </xsl:text>
          <xsl:value-of select="../@name"/>
          <xsl:text>(</xsl:text>
          <xsl:for-each select="part">
            <xsl:value-of select="." />
            <xsl:if test="not (position() = last())">
              <xsl:text>, </xsl:text>
            </xsl:if>
          </xsl:for-each>
          <xsl:text>);
</xsl:text>
        </xsl:if>

      </xsl:for-each>

      <xsl:text>
</xsl:text>
    </xsl:for-each>

    <!-- fk -->
    <xsl:for-each select="table">
      <xsl:for-each select="row">
        <xsl:for-each select="relation">
          <xsl:text>ALTER TABLE </xsl:text>
          <xsl:value-of select="../../@name" />
          <xsl:text> ADD FOREIGN KEY (</xsl:text>
          <xsl:value-of select="../@name" />
          <xsl:text>) REFERENCES </xsl:text>
          <xsl:value-of select="@table" />
          <xsl:text> (</xsl:text>
          <xsl:value-of select="@row" />
          <xsl:text>);
</xsl:text>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:for-each>

  </xsl:template>
</xsl:stylesheet>
