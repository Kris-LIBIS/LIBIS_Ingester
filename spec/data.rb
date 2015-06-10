require 'libis-ingester'

def check_data(item, names)
  match_count = 0
  if item.respond_to? :namepath
    puts "Check item #{item.namepath}"
    expect(names.is_a?(Array)).to be true
    found = names.select {|n| n == item.namepath}
    expect(found.length).to be 1
    match_count += 1
  end
  if item.items.length > 0
    item.items.each { |i| match_count += check_data(i, names.select { |name| name =~ /^#{i.namepath}(\/|$)/ }) }
  end
  expect(match_count).to be names.length
  match_count
end

def list_data(item, level = 0)
  count = item.items.length
  puts '%s%s%s%s' % [
      '- ' * level,
      item.name,
      count > 0 ? " (#{count})" : '',
      item.is_a?(Libis::Ingester::FileItem) ? ' [' + item.properties[:mimetype].to_s + ']': ''
  ]
  item.items.each { |i| list_data(i, level + 1)}
end

files = <<STR
a/abc_001.gif
a/abc_002.gif
a/abc_003.gif
a/abc_004.gif
abc.gif
b/b1/b11/b11.gif
b/b1/b12/b12.gif
b/b1/b13/b13.gif
b/b1/b1_01.gif
b/b1/b1_02.gif
b/b1/b1_03.gif
b/b2/b21/b21.gif
b/b2/b22/b22.gif
b/b2/b23/b23.gif
b/b2/b2_01.gif
b/b2/b2_02.gif
b/b2/b2_03.gif
b/b_01.gif
b/b_02.gif
b/b_03.gif
c/c01.gif
c/c02.gif
c/c03.gif
c/c04.gif
c/c05.gif
c/c06.gif
c/c07.gif
STR
FILES_RECURSIVE = files.lines.map {|line| line.chomp}

files = <<STR
a
a/abc_001.gif
a/abc_002.gif
a/abc_003.gif
a/abc_004.gif
abc.gif
b
b/b1
b/b1/b11
b/b1/b11/b11.gif
b/b1/b12
b/b1/b12/b12.gif
b/b1/b13
b/b1/b13/b13.gif
b/b1/b1_01.gif
b/b1/b1_02.gif
b/b1/b1_03.gif
b/b2
b/b2/b21
b/b2/b21/b21.gif
b/b2/b22
b/b2/b22/b22.gif
b/b2/b23
b/b2/b23/b23.gif
b/b2/b2_01.gif
b/b2/b2_02.gif
b/b2/b2_03.gif
b/b_01.gif
b/b_02.gif
b/b_03.gif
c
c/c01.gif
c/c02.gif
c/c03.gif
c/c04.gif
c/c05.gif
c/c06.gif
c/c07.gif
STR
FILES_TREE = files.lines.map {|line| line.chomp}

files = <<STR
abc.gif
a
a/abc
a/abc/001.gif
a/abc/002.gif
a/abc/003.gif
a/abc/004.gif
b
b/b1
b/b1/b11
b/b1/b11/b11.gif
b/b1/b12
b/b1/b12/b12.gif
b/b1/b13
b/b1/b13/b13.gif
b/b1/b1
b/b1/b1/01.gif
b/b1/b1/02.gif
b/b1/b1/03.gif
b/b2
b/b2/b21
b/b2/b21/b21.gif
b/b2/b22
b/b2/b22/b22.gif
b/b2/b23
b/b2/b23/b23.gif
b/b2/b2
b/b2/b2/01.gif
b/b2/b2/02.gif
b/b2/b2/03.gif
b/b
b/b/01.gif
b/b/02.gif
b/b/03.gif
c
c/c01.gif
c/c02.gif
c/c03.gif
c/c04.gif
c/c05.gif
c/c06.gif
c/c07.gif
STR
FILES_GROUP = files.lines.map {|line| line.chomp}

files = <<STR
20101007
20101007/RMT_000017.xml
20101007/Funcitionele_classificatie_onderwijs.msg
20101007/Functionele_classificatie_onderwijs.docx
20101007/Inleiding_selectielijst_scholen_20110106vIV.doc
20101007/Selectielijst_gemeente_scholen_20110117.xls
20101007/Selectielijst_gemeente_scholen_20110117_inleiding.doc
20101007/Selectielijst_schoolarchieven_publicatie_VVBAD20110118.msg
20101007/Selectielijst_schoolarchieven_publicatie_VVBAD20110126.msg
20101007/Selectielijst_schoolarchieven_publicatie_VVBAD20110127.msg
20101007/vergelijking_lijst_ARA_en_VVBAD
20101007/vergelijking_lijst_ARA_en_VVBAD/nieuweMap
20101007/vergelijking_lijst_ARA_en_VVBAD/nieuweMap/FBoudrez_archivaris_DigitaalDocumentbeheer.pdf
20101007/vergelijking_lijst_ARA_en_VVBAD/Functioneel_model_SO_20101026.doc
20101007/vergelijking_lijst_ARA_en_VVBAD/Functioneel_model_SO_20101026_enkel_lijst.doc
20101007/vergelijking_lijst_ARA_en_VVBAD/Selectielijst_schoolarchieven_GO_20101129.doc
20101007/vergelijking_lijst_ARA_en_VVBAD/Selectielijst_schoolarchieven_ontwerp_VVBAD_20101129.xls
20101007/vergelijking_lijst_ARA_en_VVBAD/lijst_secundair_onderwijs_scholen.msg
20101007/vergelijking_lijst_ARA_en_VVBAD/ontwerpselectielijst_schoolarchieven.xls
20100203
20100203/20071031_FW_OCMW_selectielijsten.msg
20100203/FW_OCMW_selectielijsten.msg
20100203/lijsten_ocmw_20070216.msg
20100203/RMT_000001.xml
20100203/SelectielijstAankoopLogistiek_V9_def.pdf
20100203/SelectielijstAlgCat_V4_def.pdf
20100203/Selectielijst_Archiefbeheer_V4_def.pdf
20100203/SelectielijstFinanciën_V9_def.pdf
20100203/Selectielijst_geheel_def.pdf
20100203/SelectielijstInformatica_V6_def.pdf
20100203/SelectielijstJuridischeZaken_V5_def.pdf
20100203/Selectielijst_ocmw_goedgekeurd_20090817.pdf
20100203/Selectielijst_ocmw_inleiding_v2.pdf
20100203/SelectielijstPatrimonium_V10_def.pdf
20100203/SelectielijstPersoneel_V10_def.pdf
20100203/SelectielijstPreventieBescherming_V10_def.pdf
20100203/SelectielijstSecretariaat_V11_def.pdf
20100203/SelectielijstVZW_V8_def.pdf
20100203/VVBAD_website_inleiding.pdf
20100203/VVBAD_website_starttekst.doc
20100203/WLOA_jaarverslag_2009.doc
STR
DAV_FILES = files.lines.map {|line| line.chomp}

