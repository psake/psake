Below are some sample tasks that worked for me (fschwiet), though I'm new to cruise control.  Note that using a single apostrophe in the properties was necessary, double quotes would not work.

Note that to make this work on older versions of psake, I needed to add a line to psake.ps1.  Older versions may be missing a call to "exit $lasterrorcode" as the last line.

For this example, the source control provider has been configured to put the code at c:\build\ProjectName.git.

```
<tasks>
    <powershell>
        <!-- http://ccnetlive.thoughtworks.com/ccnet/doc/CCNET/PowerShell%20Task.html -->
        <script>psake.ps1</script>
        <scriptsDirectory>c:\build\ProjectName.git</scriptsDirectory>
        <executable>powershell.exe</executable>
        <buildArgs>.\default.ps1 -properties @{ 
            buildDirectory = 'c:\build\ProjectName.msbuild\';
            tempPath = 'c:\build\ProjectName.TestDatabases';
            sqlConnectionString = 'Database=''MyDB'';Data Source=.\;Integrated Security=True'
        }
        </buildArgs>
        <successExitCodes>0</successExitCodes>  <!-- via powershell, $LastExitCode -->
        <description>Run psake script</description>
    </powershell>
</tasks>
```

The build output is hard to read and I don't think any of Cruise Control's built in view templates address that.  I created a minimalistic stylesheet so the result is somewhat readable:

```
<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="html"/>

  <xsl:template match="/">
    <xsl:variable name="buildresults" select="/cruisecontrol/build/buildresults" />
    <xsl:apply-templates select="$buildresults" />
  </xsl:template>

  <xsl:template match="buildresults">
    <hr/>
<xsl:apply-templates />
  </xsl:template>

  <xsl:template match="message">
    <pre style="margin-top:0px; margin-bottom:0px"><xsl:value-of select="text()"/>\</pre>
  </xsl:template>
</xsl:stylesheet>
```