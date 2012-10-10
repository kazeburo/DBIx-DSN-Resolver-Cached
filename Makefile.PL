use inc::Module::Install;
name 'DBIx-DSN-Resolver-Cached';
all_from 'lib/DBIx/DSN/Resolver/Cached.pm';

requires 'DBIx::DSN::Resolver';
requires 'Cache::Memory::Simple';
requires 'parent';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
#auto_include;
WriteAll;
