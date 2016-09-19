#!/usr/bin/perl
#
#  make-tests.pl - generate WPT test cases from the testable statements wiki
#
#

use strict;

use IO::String ;
use JSON ;
use MediaWiki::API ;

# general logic:
#
# retrieve the wiki page in JSON format
#

my $dir = "/var/specops/wpt-aria-local/wai-aria/raw";

my $page = "ARIA_1.1_Testable_Statements";

my $wiki_config = {
  "api_url" => "https://www.w3.org/wiki/api.php"
};

my $MW = MediaWiki::API->new( $wiki_config );

my $page = $MW->get_page( { title => $page } );

my $theContent = $page->{'*'};

# Now let's walk through the content and build a test page for every item
#

# iterate over the content

my $io = IO::String->new($theContent);

my $state = 0;   # between items
my $current = "";
my $theCode = "";
my $theAsserts = {} ;
my $theAssertCount = 0;
my $theAPI = "";

while (<$io>) {
  # look for state
  if (m/^=== (.*) ===/) {
    if ($state != 0) {
      # we were in an item; dump it
      build_test($current, $theCode, $theAsserts) ;
      print "Finished $current\n";
    }
    $state = 1;
    $current = $1;
    $theCode = "";
    $theAsserts = {};
  }
  if ($state == 1) {
    if (m/<pre>/) {
      # we are now in the code block
      $state = 2;
    }
  }
  if ($state == 2) {
    if (m/<\/pre>/) {
      # we are done with the code block
      $state = 3;
    } else  {
      if (m/^\s/) {
        $theCode .= $_;
      }
    }
  } elsif ($state == 3) {
    # look for a table
    if (m/^\{\|/) {
      # table started
      $state = 4;
    }
  } elsif ($state == 4) {
    if (m/^\|-/) {
      # start of a table row
      $theAssertCount++;
    } elsif (m/^\|\}/) {
      # ran out of table
      $state = 5;
    } elsif (m/^\|rowspan=[0-9]\|(.*)$/) {
      $theAssertCount = 0;
      $theAPI = $1;
      $theAsserts->{$theAPI} = [ [] ] ;
    } elsif (m/^\|(.*)$/) {
      my $item = $1;
      # add into the data structure for the API
      if (!exists $theAsserts->{$theAPI}->[$theAssertCount]) {
        $theAsserts->{$theAPI}->[$theAssertCount] = [ $item ] ;
      } else {
        push(@{$theAsserts->{$theAPI}->[$theAssertCount]}, $item);
      }
    }
  }
};

if ($state != 0) {
  build_test($current, $theCode, $theAsserts) ;
  print "Finished $current\n";
}

exit 0;


sub build_test() {
  my $title = shift ;
  my $code = shift ;
  my $asserts = shift;

  if ($title eq "") {
    print "No name provided!";
    return;
  }

  if ($code eq "") {
    print "No code for $title; skipping.\n";
    return;
  }

  if ( $asserts eq {}) {
    print "No code or assertions for $title; skipping.\n";
    return;
  }

  $asserts->{WAIFAKE} = [ [ "role", "ROLE_TABLE_CELL" ], [ "shouldFail", "nothing" ] , [ "interface", "TableCell" ] ];

  # massage the data to make it more sensible
  if (exists $asserts->{"ATK"}) {
    print "processing ATK for $title\n";
    my @conditions = @{$asserts->{"ATK"}};
    for (my $i = 0; $i < scalar(@conditions); $i++) {
      my @new = ();
      my $start = 0;
      my $assert = "true";
      if ($conditions[$i]->[0] =~ m/^NOT/) {
        $start = 1;
        $assert = "false";
      }

      print qq(Looking at $title $conditions[$i]->[$start]\n);
      if ($conditions[$i]->[$start] =~ m/^ROLE_/) {
        $new[0] = "role";
        $new[1] = $conditions[$i]->[$start];
        $new[2] = $assert;
      } elsif ($conditions[$i]->[$start] =~ m/^STATE_/) {
        $new[0] = "start";
        $new[1] = $conditions[$i]->[$start];
        $new[2] = $assert;
      } elsif ($conditions[$i]->[$start] =~ m/^object attribute (.*)/) {
        $new[0] = "object";
        $new[1] = $1;
        if ($conditions[$i]->[1] eq "not exposed") {
          $new[2] = 0;
        } else {
          $new[2] = $conditions[$i]->[1];
        }
      }
      $conditions[$i] = \@new;
    }
    $asserts->{"ATK"} = \@conditions;
  }


  my $asserts_json = to_json($asserts, { pretty => 1, utf8 => 1});

  my $fileName = $title;
  $fileName =~ s/\s*$//;
  $fileName =~ s/"//g;
  $fileName =~ s/\///g;
  $fileName =~ s/\s+/_/g;
  $fileName .= "-manual.html";

  my $template = qq(<!doctype html>
<html>
<head>
<title>$title</title>
<script src="/resources/testharness.js"></script>
<script src="/resources/testharnessreport.js"></script>
<script src="/wai-aria/scripts/ATTAcomm.js"></script>
<script>
setup({explicit_timeout: true, explicit_done: true });

var theTest = new ATTAcomm(
    { title: "$title",
      steps: [
        {
          "type":  "test",
          "title": "step 1",
          "element": "test",
          "test" : $asserts_json
        }
    ]
  }
) ;
</script>
</head>
<body>
<p>This test examines the ARIA properties for $title.</p>
$code
</body>
</html>
);

  my $file ;

  if (open($file, ">", "$dir/$fileName")) {
    print $file $template;
    close $file;
  } else {
    print qq(Failed to create file "$dir/$fileName" $!\n);
  }

  return;
}


