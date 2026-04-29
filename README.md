# SubPar-Web

A deliberately sub mediocre Perl web framework built on PSGI. Not meant for production use — this is a personal project to better understand how web frameworks, HTTP, and PSGI work under the hood.

Feel free to criticize me!

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/mateirobescu/SubPar-Web/install.sh | bash
```

Then reload your shell:

```bash
source ~/.bashrc  # Linux
source ~/.zshrc   # Mac
```

## Quick Start

Create a new project:

```bash
subpar create-project myapp
cd myapp
subpar runserver
```

## CLI

```bash
subpar create-project [path]        # create a new project
subpar generate controller <name>   # generate a controller
subpar generate model <name>        # generate a model
subpar generate repository <name>   # generate a repository
subpar generate all <name>          # generate all three
subpar runserver [port]             # start the server (default: 8080)
```

## Project Structure

myapp/
├── app.psgi          # entry point
├── settings.pl       # configuration
├── cpanfile          # dependencies
├── Controller/       # HTTP handlers
├── Model/            # data models
└── Repository/       # database access

## Configuration

Edit `settings.pl`:

```perl
{
    port => 8080,
    databases => {
        main => {
            driver        => 'yourDriver',
            database_name => 'yourDbName',
            hostname      => 'yourHostname',
            port          => 'yourPort',
            username      => 'yourUsername',
            password      => 'yourPassword',
        }
    },
}
```

## Controllers

```perl
package Controller::PersonController;
use parent 'SubPar::Controller';

sub repositories {
    my ($self) = @_;
    $self->add_repo('Person', Repository::PersonRepository->new($self->get_db("main")));
}

sub routes {
    my ($self) = @_;
    $self->get("/persons",      \&get_all);
    $self->get("/persons/:id",  \&get_by_id);
    $self->post("/persons",     \&add_person);
    $self->del("/persons/:id",  \&delete_person);
}

sub get_all {
    my ($self, $req) = @_;
    return { persons => $self->get_repo('Person')->get_all };
}

sub get_by_id {
    my ($self, $req) = @_;
    my $person = $self->get_repo('Person')->get_by_id($req->route_params('id'));
    return SubPar::Response->status(404)->body({ error => "Not found" }) unless $person;
    return $person;
}

1;
```

## Models

```perl
package Model::Person;
use parent 'SubPar::Model';

sub fields {
    return [
        id         => { auto => 1, pk => 1 },
        first_name => { required => 1 },
        last_name  => { required => 1 },
        email      => { required => 1, validation => sub { $_[0] =~ /\@/ } },
    ];
}

1;
```

## Repositories

```perl
package Repository::PersonRepository;
use parent 'SubPar::Repository';

sub table { 'persons' }

sub get_all {
    my ($self) = @_;
    return $self->get_db->run(sub {
        my $sth = $_->prepare("SELECT * FROM " . $self->table);
        $sth->execute();
        return [ map { Model::Person->new(%$_) } @{$sth->fetchall_arrayref({})} ];
    });
}

1;
```

## Routing

| Syntax | Example | Description |
|--------|---------|-------------|
| Static | `/users` | exact match |
| Dynamic | `/users/:id` | captured via `$req->route_params('id')` |
| Catch-all | `/files/**` | captured via `$req->remaining_path` |

## Responses

```perl
# simple - returns 200 JSON automatically
return { name => "Matei" };

# full control
return SubPar::Response->status(201)->body({ name => "Matei" });
return SubPar::Response->status(404)->body({ error => "not found" });
return SubPar::Response->status(200)
    ->content_type(SubPar::ContentType::CT_HTML)
    ->body({ file => "./template.html" });
```

## Requirements

- Perl 5.32+
- cpanm
- git

## Author

Matei-Gabriel Robescu

## License

MIT