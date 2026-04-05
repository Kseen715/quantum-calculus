import os

# Use XeLaTeX instead of pdflatex to support Unicode / Cyrillic
c.PDFExporter.latex_command = ['xelatex', '{filename}']

# Point to the custom cyrillic-xetex template in this directory
c.PDFExporter.template_name = 'cyrillic-xetex'
c.TemplateExporter.extra_template_basedirs = [os.path.dirname(__file__)]
