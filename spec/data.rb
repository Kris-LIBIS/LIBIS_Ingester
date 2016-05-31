require 'libis-ingester'

def check_data(item, names, print_log = false)
  match_count = 0
  if item.respond_to? :namepath
    puts "Check item #{item.namepath}" if print_log
    expect(names).to be_a Array
    found = names.select { |n| n == item.labelpath }
    expect(found.length).to be 1
    match_count += 1
  end
  if item.items.length > 0
    item.items.each { |i| match_count += check_data(i, names.select { |name| name =~ /^#{i.labelpath}(\/|$)/ }, print_log) }
  end
  puts "check match_count (#{match_count}) against expected (#{names.length}) for #{item.namepath} ..." if print_log
  expect(match_count).to be names.length
  puts "item #{item.namepath} OK" if print_log
  match_count
end

def check_list(item, list, level = 0)
  count = item.items.length
  value = list.shift
  expect('%s%s%s%s' % [
             '- ' * level,
             item.label,
             count > 0 ? " (#{count})" : '',
             item.is_a?(Libis::Ingester::FileItem) ? ' [' + item.properties['mimetype'].to_s + ']' : ''
         ]).to eq value
  item.items.each { |i| check_list(i, list, level + 1) }
end

def list_data(item, level = 0)
  count = item.items.length
  puts '%s%s%s%s' % [
           '- ' * level,
           item.name,
           count > 0 ? " (#{count})" : '',
           item.is_a?(Libis::Ingester::FileItem) ? ' [' + item.properties['mimetype'].to_s + ']' : ''
       ]
  item.items.each { |i| list_data(i, level + 1) }
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
FILES_RECURSIVE = files.lines.map { |line| line.chomp }

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
FILES_TREE = files.lines.map { |line| line.chomp }

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
FILES_GROUP = files.lines.map { |line| line.chomp }

files = <<STR
dir_a
dir_a/dir_a1
dir_a/dir_a1/abc.doc
dir_a/dir_a1/abc.doc/abc.doc
dir_a/dir_a1/def.doc
dir_a/dir_a1/def.doc/def.doc
dir_a/dir_a2
dir_a/dir_a2/book-abc
dir_a/dir_a2/book-abc/page-1
dir_a/dir_a2/book-abc/page-2
dir_a/dir_a2/book-def
dir_a/dir_a2/book-def/page-1
dir_a/dir_a2/book-def/page-2
test.pdf
test.pdf/test.pdf
STR
FILE_WITH_IE_COLLECTIONS = files.lines.map { |line| line.chomp }

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
test.pdf/test.pdf
STR
FILE_WITH_IE_COMPLEX = files.lines.map { |line| line.chomp }

files = <<STR
- dir_a (2)
- - dir_a1 (2)
- - - abc.doc (4)
- - - - abc.doc [application/msword]
- - - - Archive (1)
- - - - - abc.doc [application/msword]
- - - - HQ view (1)
- - - - - abc.doc [application/msword]
- - - - LQ watermarked (1)
- - - - - abc.doc [application/pdf]
- - - def.doc (4)
- - - - def.doc [application/msword]
- - - - Archive (1)
- - - - - def.doc [application/msword]
- - - - HQ view (1)
- - - - - def.doc [application/msword]
- - - - LQ watermarked (1)
- - - - - def.doc [application/pdf]
- - dir_a2 (2)
- - - book-abc (3)
- - - - page-1 [image/jpeg]
- - - - page-2 [image/jpeg]
- - - - Archive (2)
- - - - - page-1 [image/jpeg]
- - - - - page-2 [image/jpeg]
- - - - HQ view (2)
- - - - - page-1 [image/jpeg]
- - - - - page-2 [image/jpeg]
- - - - LQ watermarked (2)
- - - - - page-1 [image/jpeg]
- - - - - page-2 [image/jpeg]
- - - book-def (3)
- - - - page-1 [image/jpeg]
- - - - page-2 [image/jpeg]
- - - - Archive (2)
- - - - - page-1 [image/jpeg]
- - - - - page-2 [image/jpeg]
- - - - HQ view (2)
- - - - - page-1 [image/jpeg]
- - - - - page-2 [image/jpeg]
- - - - LQ watermarked (2)
- - - - - page-1 [image/jpeg]
- - - - - page-2 [image/jpeg]
- test.pdf (4)
- - test.pdf [application/pdf]
- - Archive (1)
- - - test.pdf [application/pdf]
- - HQ view (1)
- - - test.pdf [application/pdf]
- - LQ watermarked (1)
- - - test.pdf [application/pdf]
STR
COMPLEX_INGEST = files.lines.map { |line| line.chomp }

