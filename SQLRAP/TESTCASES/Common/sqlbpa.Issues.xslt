<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:template match="/">
		<html xmlns="http://www.w3.org/1999/xhtml">
			<body>
				<h2>Results</h2>
				<table id="tableIssues" style="font-size:12px;">
					<xsl:for-each select="WorkItem/Data/Messages/Message">
						<tr>
							<td>
								<table id="tableIssue" style="font-size:12px;border-style:solid;border-width:5px;border-color:white" width="100%" >
									<tr>
										<td valign="top" style="background:#9caeff" width="15%">Issue</td>
										<td style="background:#cccccc;">
											<xsl:value-of select="@Title"/>
										</td>
									</tr>									
									<tr>
										<td valign="top" style="background:#9caeff">Affected Object</td>
										<td style="background:#cccccc">
											<xsl:for-each select="AffectedObjects/Object">
												&#8226;<xsl:value-of select="."/><br/>
											</xsl:for-each>
										</td>
									</tr>
								</table>
							</td>
						</tr>
					</xsl:for-each>
				</table>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>