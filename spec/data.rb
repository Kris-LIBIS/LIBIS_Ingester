require 'libis-ingester'

def check_data(item, names)
  match_count = 0
  if item.respond_to? :namepath
    # puts "Check item #{item.namepath}"
    expect(names).to be_a Array
    found = names.select {|n| n == item.namepath}
    expect(found.length).to be 1
    match_count += 1
  end
  if item.items.length > 0
    item.items.each { |i| match_count += check_data(i, names.select { |name| name =~ /^#{i.namepath}(\/|$)/ }) }
  end
  expect(match_count).to be names.length
  # puts "item #{item.namepath} OK"
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
abc.doc
def.doc
abc-1.jpg
abc-2.jpg
def-1.jpg
def-2.jpg
test.pdf
STR
FILES_RECURSIVE = files.lines.map {|line| line.chomp}

files = <<STR
dir_a
dir_a/dir_a1
dir_a/dir_a1/abc.doc
dir_a/dir_a1/def.doc
dir_a/dir_a2
dir_a/dir_a2/abc-1.jpg
dir_a/dir_a2/abc-2.jpg
dir_a/dir_a2/def-1.jpg
dir_a/dir_a2/def-2.jpg
test.pdf
STR
FILES_TREE = files.lines.map {|line| line.chomp}

files = <<STR
dir_a
dir_a/dir_a1
dir_a/dir_a1/abc.doc
dir_a/dir_a1/def.doc
dir_a/dir_a2
dir_a/dir_a2/book-abc
dir_a/dir_a2/book-abc/page-1
dir_a/dir_a2/book-abc/page-2
dir_a/dir_a2/book-def
dir_a/dir_a2/book-def/page-1
dir_a/dir_a2/book-def/page-2
test.pdf
STR
FILES_GROUP = files.lines.map {|line| line.chomp}

files = <<STR
dir_a
dir_a/dir_a1
dir_a/dir_a1/abc.doc
dir_a/dir_a1/abc.doc/Archiefkopie
dir_a/dir_a1/abc.doc/Archiefkopie/abc.doc
dir_a/dir_a1/def.doc
dir_a/dir_a1/def.doc/Archiefkopie
dir_a/dir_a1/def.doc/Archiefkopie/def.doc
dir_a/dir_a2
dir_a/dir_a2/book-abc
dir_a/dir_a2/book-abc/Archiefkopie
dir_a/dir_a2/book-abc/Archiefkopie/page-1
dir_a/dir_a2/book-abc/Archiefkopie/page-2
dir_a/dir_a2/book-def
dir_a/dir_a2/book-def/Archiefkopie
dir_a/dir_a2/book-def/Archiefkopie/page-1
dir_a/dir_a2/book-def/Archiefkopie/page-2
test.pdf
test.pdf/Archiefkopie
test.pdf/Archiefkopie/test.pdf
STR
FILE_WITH_IE_COLLECTIONS = files.lines.map {|line| line.chomp}

files = <<STR
dir_a
dir_a/Archiefkopie
dir_a/Archiefkopie/dir_a1
dir_a/Archiefkopie/dir_a1/abc.doc
dir_a/Archiefkopie/dir_a1/def.doc
dir_a/Archiefkopie/dir_a2
dir_a/Archiefkopie/dir_a2/book-abc
dir_a/Archiefkopie/dir_a2/book-abc/page-1
dir_a/Archiefkopie/dir_a2/book-abc/page-2
dir_a/Archiefkopie/dir_a2/book-def
dir_a/Archiefkopie/dir_a2/book-def/page-1
dir_a/Archiefkopie/dir_a2/book-def/page-2
test.pdf
test.pdf/Archiefkopie
test.pdf/Archiefkopie/test.pdf
STR
FILE_WITH_IE_COMPLEX = files.lines.map {|line| line.chomp}
