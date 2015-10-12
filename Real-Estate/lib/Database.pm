package Database;

use strict;

use Conf;
use DBI;

my $conf = new Conf;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->{dbh} ||= $self->_connect;
    return $self;
}

sub _connect {
    my $self = shift;
    return $self->{dbh} if $self->{dbh};

    my $db   = $conf->{db}{name};
    my $host = $conf->{db}{host};
    my $user = $conf->{db}{user};
    my $pass = $conf->{db}{pass};

    $self->{dbh} = DBI->connect("DBI:mysql:$db:$host", $user, $pass)
        or die "Connection Failed $DBI::errstr";
    return $self->{dbh};
}

sub insert {
    my ($self, $table, $data) = @_;

    my $fields = join ',', keys %{$data};
    my $values = join ',', map { $self->{dbh}->quote($_) } values %{$data};

    my $query = "INSERT INTO $table ($fields) VALUES ($values)";
    return $self->{dbh}->do($query) or die $self->{dbh}->errstr;
}

sub update {
    my ($self, $table, $data, $cond) = @_;

    my $set = join(', ',
        map { "$_ = " . $self->{dbh}->quote($data->{$_}) } keys %{$data} );
    my $where = join(' AND ',
        map { "$_ = " . $self->{dbh}->quote($cond->{$_}) } keys %{$cond});

    my $query = "UPDATE $table SET $set WHERE $where";
    return $self->{dbh}->do($query) or die $self->{dbh}->errstr;
}

sub delete {
    my ($self, $table, $field, $value) = @_;

    my $query = "DELETE FROM $table WHERE $field = " . $self->{dbh}->quote($value);
    return $self->{dbh}->do($query) or die $self->{dbh}->errstr;
}

sub prepare_insert {
    my ($self, $city, $source) = @_;
    my $sth = $self->{dbh}->prepare("
        INSERT INTO ad
            (city, source, title, type, summary, locality, price, time, link)
        VALUES
            ('$city', '$source', ?, ?, ?, ?, ?, ?, ?)
    ") or return;
    return $sth;
}

sub prepare_replace {
    my ($self, $source) = @_;
    my $sth = $self->{dbh}->prepare("
        REPLACE INTO ad
            (city, source, title, type, summary, locality, price, time, link)
        VALUES
            (?, '$source', ?, ?, ?, ?, ?, ?, ?)
    ") or die $self->{dbh}->errstr;
    return $sth;
}

sub DESTROY {
    my $self = shift;

    $self->{dbh}->disconnect if $self->{dbh};
}

1;
