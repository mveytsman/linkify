defmodule AutoLinkerTest do
  use ExUnit.Case
  doctest AutoLinker

  test "phone number" do
    assert AutoLinker.link(", work (555) 555-5555", phone: true) ==
             ~s{, work <a href="#" class="phone-number" data-phone="5555555555">(555) 555-5555</a>}
  end

  test "default link" do
    assert AutoLinker.link("google.com") ==
             "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"
  end

  test "markdown" do
    assert AutoLinker.link("[google.com](http://google.com)", markdown: true) ==
             "<a href='http://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"
  end

  test "does on link existing links" do
    assert AutoLinker.link("<a href='http://google.com'>google.com</a>") ==
             "<a href='http://google.com'>google.com</a>"
  end

  test "phone number and markdown link" do
    assert AutoLinker.link("888 888-8888  [ab](a.com)", phone: true, markdown: true) ==
             "<a href=\"#\" class=\"phone-number\" data-phone=\"8888888888\">888 888-8888</a>" <>
               "  <a href='a.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>ab</a>"
  end

  test "all kinds of links" do
    text =
      "hello @user google.com https://ddg.com 888 888-8888 #tag user@email.com [google.com](http://google.com) irc:///mIRC"

    expected =
      "hello <a href='https://example.com/user/user'>@user</a> <a href='http://google.com'>google.com</a> <a href='https://ddg.com'>ddg.com</a> <a href=\"#\" class=\"phone-number\" data-phone=\"8888888888\">888 888-8888</a> <a href='https://example.com/tag/tag'>#tag</a> <a href='mailto:user@email.com' >user@email.com</a> <a href='http://google.com'>google.com</a> <a href='irc:///mIRC' >irc:///mIRC</a>"

    assert AutoLinker.link(text,
             phone: true,
             markdown: true,
             email: true,
             mention: true,
             mention_prefix: "https://example.com/user/",
             hashtag: true,
             hashtag_prefix: "https://example.com/tag/",
             scheme: true,
             extra: true,
             class: false,
             new_window: false,
             rel: false
           ) == expected
  end

  describe "mentions" do
    test "simple mentions" do
      expected =
        ~s{hello <a href='https://example.com/user/user' class='auto-linker' target='_blank' rel='noopener noreferrer'>@user</a> and <a href='https://example.com/user/anotherUser' class='auto-linker' target='_blank' rel='noopener noreferrer'>@anotherUser</a>}

      assert AutoLinker.link("hello @user and @anotherUser",
               mention: true,
               mention_prefix: "https://example.com/user/"
             ) == expected
    end

    test "metion @user@example.com" do
      text = "hey @user@example.com"

      expected =
        "hey <a href='https://example.com/user/user@example.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>@user@example.com</a>"

      assert AutoLinker.link(text,
               mention: true,
               mention_prefix: "https://example.com/user/"
             ) == expected
    end

    test "skip if starts with @@" do
      text = "hello @@user and @anotherUser"

      expected =
        "hello @@user and <a href='https://example.com/user/anotherUser' class='auto-linker' target='_blank' rel='noopener noreferrer'>@anotherUser</a>"

      assert AutoLinker.link(text,
               mention: true,
               mention_prefix: "https://example.com/user/"
             ) == expected
    end
  end

  describe "hashtag links" do
    test "hashtag" do
      expected =
        "one <a href='https://example.com/tag/two' class='auto-linker' target='_blank' rel='noopener noreferrer'>#two</a> three <a href='https://example.com/tag/four' class='auto-linker' target='_blank' rel='noopener noreferrer'>#four</a>"

      assert AutoLinker.link("one #two three #four",
               hashtag: true,
               hashtag_prefix: "https://example.com/tag/"
             ) == expected
    end

    test "do not turn urls with hashes into hashtags" do
      text = "google.com#test #test google.com/#test #tag"

      expected =
        "<a href='http://google.com#test'>google.com#test</a> <a href='https://example.com/tag/test'>#test</a> <a href='http://google.com/#test'>google.com/#test</a> <a href='https://example.com/tag/tag'>#tag</a>"

      assert AutoLinker.link(text,
               scheme: true,
               hashtag: true,
               class: false,
               new_window: false,
               rel: false,
               hashtag_prefix: "https://example.com/tag/"
             ) == expected
    end

    test "works with non-latin characters" do
      text = "#漢字 #は #тест #ทดสอบ"

      expected =
        "<a href='https://example.com/tag/漢字'>#漢字</a> <a href='https://example.com/tag/は'>#は</a> <a href='https://example.com/tag/тест'>#тест</a> <a href='https://example.com/tag/ทดสอบ'>#ทดสอบ</a>"

      assert AutoLinker.link(text,
               scheme: true,
               class: false,
               new_window: false,
               rel: false,
               hashtag: true,
               hashtag_prefix: "https://example.com/tag/"
             ) == expected
    end
  end

  describe "links" do
    test "turning urls into links" do
      text = "Hey, check out http://www.youtube.com/watch?v=8Zg1-TufF%20zY?x=1&y=2#blabla ."

      expected =
        "Hey, check out <a href='http://www.youtube.com/watch?v=8Zg1-TufF%20zY?x=1&y=2#blabla' class='auto-linker' target='_blank' rel='noopener noreferrer'>youtube.com/watch?v=8Zg1-TufF%20zY?x=1&y=2#blabla</a> ."

      assert AutoLinker.link(text, scheme: true) == expected

      # no scheme
      text = "Hey, check out www.youtube.com/watch?v=8Zg1-TufF%20zY?x=1&y=2#blabla ."
      assert AutoLinker.link(text, scheme: true) == expected
    end

    test "hostname/@user" do
      text = "https://example.com/@user"

      expected =
        "<a href='https://example.com/@user' class='auto-linker' target='_blank' rel='noopener noreferrer'>example.com/@user</a>"

      assert AutoLinker.link(text, scheme: true) == expected

      text = "https://example.com:4000/@user"

      expected =
        "<a href='https://example.com:4000/@user' class='auto-linker' target='_blank' rel='noopener noreferrer'>example.com:4000/@user</a>"

      assert AutoLinker.link(text, scheme: true) == expected

      text = "https://example.com:4000/@user"

      expected =
        "<a href='https://example.com:4000/@user' class='auto-linker' target='_blank' rel='noopener noreferrer'>example.com:4000/@user</a>"

      assert AutoLinker.link(text, scheme: true) == expected

      text = "@username"
      expected = "@username"
      assert AutoLinker.link(text, scheme: true) == expected

      text = "http://www.cs.vu.nl/~ast/intel/"

      expected =
        "<a href='http://www.cs.vu.nl/~ast/intel/' class='auto-linker' target='_blank' rel='noopener noreferrer'>cs.vu.nl/~ast/intel/</a>"

      assert AutoLinker.link(text, scheme: true) == expected

      text = "https://forum.zdoom.org/viewtopic.php?f=44&t=57087"

      expected =
        "<a href='https://forum.zdoom.org/viewtopic.php?f=44&t=57087' class='auto-linker' target='_blank' rel='noopener noreferrer'>forum.zdoom.org/viewtopic.php?f=44&t=57087</a>"

      assert AutoLinker.link(text, scheme: true) == expected

      text = "https://en.wikipedia.org/wiki/Sophia_(Gnosticism)#Mythos_of_the_soul"

      expected =
        "<a href='https://en.wikipedia.org/wiki/Sophia_(Gnosticism)#Mythos_of_the_soul' class='auto-linker' target='_blank' rel='noopener noreferrer'>en.wikipedia.org/wiki/Sophia_(Gnosticism)#Mythos_of_the_soul</a>"

      assert AutoLinker.link(text, scheme: true) == expected

      text = "https://en.wikipedia.org/wiki/Duff's_device"

      expected =
        "<a href='https://en.wikipedia.org/wiki/Duff's_device' class='auto-linker' target='_blank' rel='noopener noreferrer'>en.wikipedia.org/wiki/Duff's_device</a>"

      assert AutoLinker.link(text, scheme: true) == expected
    end
  end

  describe "non http links" do
    test "xmpp" do
      text = "xmpp:user@example.com"
      expected = "<a href='xmpp:user@example.com' class='auto-linker'>xmpp:user@example.com</a>"
      assert AutoLinker.link(text, extra: true) == expected
    end

    test "email" do
      text = "user@example.com"
      expected = "<a href='mailto:user@example.com' class='auto-linker'>user@example.com</a>"
      assert AutoLinker.link(text, email: true) == expected
    end

    test "magnet" do
      text =
        "magnet:?xt=urn:btih:a4104a9d2f5615601c429fe8bab8177c47c05c84&dn=ubuntu-18.04.1.0-live-server-amd64.iso&tr=http%3A%2F%2Ftorrent.ubuntu.com%3A6969%2Fannounce&tr=http%3A%2F%2Fipv6.torrent.ubuntu.com%3A6969%2Fannounce"

      expected =
        "<a href='magnet:?xt=urn:btih:a4104a9d2f5615601c429fe8bab8177c47c05c84&dn=ubuntu-18.04.1.0-live-server-amd64.iso&tr=http%3A%2F%2Ftorrent.ubuntu.com%3A6969%2Fannounce&tr=http%3A%2F%2Fipv6.torrent.ubuntu.com%3A6969%2Fannounce' class='auto-linker'>magnet:?xt=urn:btih:a4104a9d2f5615601c429fe8bab8177c47c05c84&dn=ubuntu-18.04.1.0-live-server-amd64.iso&tr=http%3A%2F%2Ftorrent.ubuntu.com%3A6969%2Fannounce&tr=http%3A%2F%2Fipv6.torrent.ubuntu.com%3A6969%2Fannounce</a>"

      assert AutoLinker.link(text, extra: true) == expected
    end

    test "dweb" do
      text =
        "dweb://584faa05d394190ab1a3f0240607f9bf2b7e2bd9968830a11cf77db0cea36a21+v1.0.0/path/to/file.txt"

      expected =
        "<a href='dweb://584faa05d394190ab1a3f0240607f9bf2b7e2bd9968830a11cf77db0cea36a21+v1.0.0/path/to/file.txt' class='auto-linker'>dweb://584faa05d394190ab1a3f0240607f9bf2b7e2bd9968830a11cf77db0cea36a21+v1.0.0/path/to/file.txt</a>"

      assert AutoLinker.link(text, extra: true) == expected
    end
  end

  describe "TLDs" do
    test "parse with scheme" do
      text = "https://google.com"

      expected =
        "<a href='https://google.com' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.com</a>"

      assert AutoLinker.link(text, scheme: true) == expected
    end

    test "only existing TLDs with scheme" do
      text = "this url https://google.foobar.blah11blah/ has invalid TLD"

      expected = "this url https://google.foobar.blah11blah/ has invalid TLD"
      assert AutoLinker.link(text, scheme: true) == expected

      text = "this url https://google.foobar.com/ has valid TLD"

      expected =
        "this url <a href='https://google.foobar.com/' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.foobar.com/</a> has valid TLD"

      assert AutoLinker.link(text, scheme: true) == expected
    end

    test "only existing TLDs without scheme" do
      text = "this url google.foobar.blah11blah/ has invalid TLD"
      expected = "this url google.foobar.blah11blah/ has invalid TLD"
      assert AutoLinker.link(text, scheme: false) == expected

      text = "this url google.foobar.com/ has valid TLD"

      expected =
        "this url <a href='http://google.foobar.com/' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.foobar.com/</a> has valid TLD"

      assert AutoLinker.link(text, scheme: false) == expected
    end

    test "only existing TLDs with and without scheme" do
      text = "this url http://google.foobar.com/ has valid TLD"

      expected =
        "this url <a href='http://google.foobar.com/' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.foobar.com/</a> has valid TLD"

      assert AutoLinker.link(text, scheme: true) == expected

      text = "this url google.foobar.com/ has valid TLD"

      expected =
        "this url <a href='http://google.foobar.com/' class='auto-linker' target='_blank' rel='noopener noreferrer'>google.foobar.com/</a> has valid TLD"

      assert AutoLinker.link(text, scheme: true) == expected
    end
  end
end
