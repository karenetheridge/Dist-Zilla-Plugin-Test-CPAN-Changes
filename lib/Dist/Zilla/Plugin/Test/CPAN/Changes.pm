package Dist::Zilla::Plugin::Test::CPAN::Changes;
use strict;
use warnings;
# ABSTRACT: release tests for your changelog

our $VERSION = '0.013';

use Moose;
use Sub::Exporter::ForMethods;
use Data::Section 0.200002 { installer => Sub::Exporter::ForMethods::method_installer }, '-setup';

with
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::PrereqSource',
    'Dist::Zilla::Role::TextTemplate';

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::CPAN::Changes]

=begin :prelude

=for test_synopsis BEGIN { die "SKIP: synopsis isn't perl code" }

=end :prelude

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

    xt/release/cpan-changes.t - a standard Test::CPAN::Changes test

See L<Test::CPAN::Changes> for what this test does.

=head1 CONFIGURATION OPTIONS

=head2 changelog

The file name of the change log file to test. Defaults to F<Changes>.

If you want to use a different filename for whatever reason, do:

    [Test::CPAN::Changes]
    changelog = CHANGES

and that file will be tested instead.

=head2 filename

The name of the test file to be generated. Defaults to
F<xt/release/cpan-changes.t>.

=cut

has changelog => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Changes',
);

has filename => (
    is      => 'ro',
    isa     => 'Str',
    default => 'xt/release/cpan-changes.t',
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        changelog => $self->changelog,
        filename  => $self->filename,
        blessed($self) ne __PACKAGE__
            ? ( version => (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev') )
            : (),
    };
    return $config;
};

=for Pod::Coverage gather_files register_prereqs

=cut

sub gather_files {
    my $self = shift;

    require Dist::Zilla::File::InMemory;

    my $content = ${$self->section_data('__TEST__')};

    my $final_content = $self->fill_in_string(
        $content,
        {
            changes_filename => \($self->changelog),
            plugin           => \$self,
        },
    );

    $self->add_file( Dist::Zilla::File::InMemory->new(
        name => $self->filename,
        content => $final_content,
    ));

    return;
}

# Register the release test prereq as a "develop requires"
# so it will be listed in "dzil listdeps --author"
sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    {
      type  => 'requires',
      phase => 'develop',
    },
    # Latest known release of Test::CPAN::Changes
    # because CPAN authors must use the latest if we want
    # this check to be relevant
    'Test::CPAN::Changes'     => '0.19',
  );
}





__PACKAGE__->meta->make_immutable;
no Moose;

__DATA__
__[ __TEST__ ]__
use strict;
use warnings;

# this test was generated with {{ ref($plugin) . ' ' . $plugin->VERSION }}

use Test::More 0.96 tests => 1;
use Test::CPAN::Changes;
subtest 'changes_ok' => sub {
    changes_file_ok('{{ $changes_filename }}');
};
