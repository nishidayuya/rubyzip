require 'test_helper'

class ZipEntryTest < MiniTest::Test
  include ZipEntryData

  def test_constructor_and_getters
    entry = ::Zip::Entry.new(TEST_ZIPFILE,
                             TEST_NAME,
                             TEST_COMMENT,
                             TEST_EXTRA,
                             TEST_COMPRESSED_SIZE,
                             TEST_CRC,
                             TEST_COMPRESSIONMETHOD,
                             TEST_COMPRESSIONLEVEL,
                             TEST_SIZE,
                             TEST_TIME)

    assert_equal(TEST_COMMENT, entry.comment)
    assert_equal(TEST_COMPRESSED_SIZE, entry.compressed_size)
    assert_equal(TEST_CRC, entry.crc)
    assert_instance_of(::Zip::ExtraField, entry.extra)
    assert_equal(TEST_COMPRESSIONMETHOD, entry.compression_method)
    assert_equal(TEST_NAME, entry.name)
    assert_equal(TEST_SIZE, entry.size)
    assert_equal(TEST_TIME, entry.time)
  end

  def test_is_directory_and_is_file
    assert(::Zip::Entry.new(TEST_ZIPFILE, 'hello').file?)
    assert(!::Zip::Entry.new(TEST_ZIPFILE, 'hello').directory?)

    assert(::Zip::Entry.new(TEST_ZIPFILE, 'dir/hello').file?)
    assert(!::Zip::Entry.new(TEST_ZIPFILE, 'dir/hello').directory?)

    assert(::Zip::Entry.new(TEST_ZIPFILE, 'hello/').directory?)
    assert(!::Zip::Entry.new(TEST_ZIPFILE, 'hello/').file?)

    assert(::Zip::Entry.new(TEST_ZIPFILE, 'dir/hello/').directory?)
    assert(!::Zip::Entry.new(TEST_ZIPFILE, 'dir/hello/').file?)
  end

  def test_equality
    entry1 = ::Zip::Entry.new('file.zip', 'name', 'isNotCompared',
                              'something extra', 123, 1234,
                              ::Zip::Entry::DEFLATED, ::Zip.default_compression, 10_000)
    entry2 = ::Zip::Entry.new('file.zip', 'name', 'isNotComparedXXX',
                              'something extra', 123, 1234,
                              ::Zip::Entry::DEFLATED, ::Zip.default_compression, 10_000)
    entry3 = ::Zip::Entry.new('file.zip', 'name2', 'isNotComparedXXX',
                              'something extra', 123, 1234,
                              ::Zip::Entry::DEFLATED, ::Zip.default_compression, 10_000)
    entry4 = ::Zip::Entry.new('file.zip', 'name2', 'isNotComparedXXX',
                              'something extraXX', 123, 1234,
                              ::Zip::Entry::DEFLATED, ::Zip.default_compression, 10_000)
    entry5 = ::Zip::Entry.new('file.zip', 'name2', 'isNotComparedXXX',
                              'something extraXX', 12, 1234,
                              ::Zip::Entry::DEFLATED, ::Zip.default_compression, 10_000)
    entry6 = ::Zip::Entry.new('file.zip', 'name2', 'isNotComparedXXX',
                              'something extraXX', 12, 123,
                              ::Zip::Entry::DEFLATED, ::Zip.default_compression, 10_000)
    entry7 = ::Zip::Entry.new('file.zip', 'name2', 'isNotComparedXXX',
                              'something extraXX', 12, 123,
                              ::Zip::Entry::STORED, ::Zip.default_compression, 10_000)
    entry8 = ::Zip::Entry.new('file.zip', 'name2', 'isNotComparedXXX',
                              'something extraXX', 12, 123,
                              ::Zip::Entry::STORED, ::Zip.default_compression, 100_000)

    assert_equal(entry1, entry1)
    assert_equal(entry1, entry2)

    assert(entry2 != entry3)
    assert(entry3 != entry4)
    assert(entry4 != entry5)
    assert(entry5 != entry6)
    assert(entry6 != entry7)
    assert(entry7 != entry8)

    assert(entry7 != 'hello')
    assert(entry7 != 12)
  end

  def test_compare
    assert_equal(0, (::Zip::Entry.new('zf.zip', 'a') <=> ::Zip::Entry.new('zf.zip', 'a')))
    assert_equal(1, (::Zip::Entry.new('zf.zip', 'b') <=> ::Zip::Entry.new('zf.zip', 'a')))
    assert_equal(-1, (::Zip::Entry.new('zf.zip', 'a') <=> ::Zip::Entry.new('zf.zip', 'b')))

    entries = [
      ::Zip::Entry.new('zf.zip', '5'),
      ::Zip::Entry.new('zf.zip', '1'),
      ::Zip::Entry.new('zf.zip', '3'),
      ::Zip::Entry.new('zf.zip', '4'),
      ::Zip::Entry.new('zf.zip', '0'),
      ::Zip::Entry.new('zf.zip', '2')
    ]

    entries.sort!
    assert_equal('0', entries[0].to_s)
    assert_equal('1', entries[1].to_s)
    assert_equal('2', entries[2].to_s)
    assert_equal('3', entries[3].to_s)
    assert_equal('4', entries[4].to_s)
    assert_equal('5', entries[5].to_s)
  end

  def test_parent_as_string
    entry1 = ::Zip::Entry.new('zf.zip', 'aa')
    entry2 = ::Zip::Entry.new('zf.zip', 'aa/')
    entry3 = ::Zip::Entry.new('zf.zip', 'aa/bb')
    entry4 = ::Zip::Entry.new('zf.zip', 'aa/bb/')
    entry5 = ::Zip::Entry.new('zf.zip', 'aa/bb/cc')
    entry6 = ::Zip::Entry.new('zf.zip', 'aa/bb/cc/')

    assert_nil(entry1.parent_as_string)
    assert_nil(entry2.parent_as_string)
    assert_equal('aa/', entry3.parent_as_string)
    assert_equal('aa/', entry4.parent_as_string)
    assert_equal('aa/bb/', entry5.parent_as_string)
    assert_equal('aa/bb/', entry6.parent_as_string)
  end

  def test_entry_name_cannot_start_with_slash
    assert_raises(::Zip::EntryNameError) { ::Zip::Entry.new('zf.zip', '/hej/der') }
  end

  def test_store_file_without_compression
    File.delete('/tmp/no_compress.zip') if File.exist?('/tmp/no_compress.zip')
    files = Dir[File.join('test/data/globTest', '**', '**')]

    Zip.setup do |z|
      z.write_zip64_support = false
    end

    zipfile = Zip::File.open('/tmp/no_compress.zip', Zip::File::CREATE)
    mimetype_entry = Zip::Entry.new(zipfile,                # @zipfile
                                    'mimetype',             # @name
                                    '',                     # @comment
                                    '',                     # @extra
                                    0,                      # @compressed_size
                                    0,                      # @crc
                                    Zip::Entry::STORED)     # @comppressed_method

    zipfile.add(mimetype_entry, 'test/data/mimetype')

    files.each do |file|
      zipfile.add(file.sub('test/data/globTest/', ''), file)
    end
    zipfile.close

    f = File.open('/tmp/no_compress.zip', 'rb')
    first_100_bytes = f.read(100)
    f.close

    assert_match(/mimetypeapplication\/epub\+zip/, first_100_bytes)
  end

  def test_encrypted?
    entry = Zip::Entry.new
    entry.gp_flags = 1
    assert_equal(true, entry.encrypted?)

    entry.gp_flags = 0
    assert_equal(false, entry.encrypted?)
  end

  def test_incomplete?
    entry = Zip::Entry.new
    entry.gp_flags = 8
    assert_equal(true, entry.incomplete?)

    entry.gp_flags = 0
    assert_equal(false, entry.incomplete?)
  end

  def test_compression_level_flags
    [
      [Zip.default_compression, 0],
      [0, 0],
      [1, 6],
      [2, 4],
      [3, 0],
      [7, 0],
      [8, 2],
      [9, 2]
    ].each do |level, flags|
      # Check flags are set correctly when DEFLATED is specified.
      e_def = Zip::Entry.new('', '', '', '', 0, 0, Zip::Entry::DEFLATED, level)
      assert_equal(flags, e_def.gp_flags & 0b110)

      # Check that flags are not set when STORED is specified.
      e_sto = Zip::Entry.new('', '', '', '', 0, 0, Zip::Entry::STORED, level)
      assert_equal(0, e_sto.gp_flags & 0b110)
    end

    # Check that a directory entry's flags are not set, even if DEFLATED
    # is specified.
    e_dir = Zip::Entry.new('', 'd/', '', '', 0, 0, Zip::Entry::DEFLATED, 1)
    assert_equal(0, e_dir.gp_flags & 0b110)
  end
end
