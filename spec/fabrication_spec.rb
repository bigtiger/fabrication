require 'spec_helper'

describe Fabrication do

  context 'static fields' do

    let(:person) do
      Fabricate(:person, :last_name => 'Awesome')
    end

    before(:all) do
      Fabricator(:person) do
        first_name 'Joe'
        last_name 'Schmoe'
        age 78
      end
    end

    it 'has the default first name' do
      person.first_name.should == 'Joe'
    end

    it 'has an overridden last name' do
      person.last_name.should == 'Awesome'
    end

    it 'has the default age' do
      person.age.should == 78
    end

    it 'generates a fresh object every time' do
      Fabricate(:person).should_not == person
    end

  end

  context 'block generated fields' do

    let(:person) do
      Fabricate(:person)
    end

    before(:all) do
      Fabricator(:person) do
        first_name { Faker::Name.first_name }
        last_name { Faker::Name.last_name }
        age { rand(100) }
        shoes(:count => 10) { |person, i| "shoe #{i}" }
      end
    end

    it 'has a first name' do
      person.first_name.should be
    end

    it 'has a last name' do
      person.last_name.should be
    end

    it 'has an age' do
      person.age.should be
    end

    it 'has 10 shoes' do
      person.shoes.should == (1..10).map { |i| "shoe #{i}" }
    end

  end

  context 'with the generation parameter' do

    before(:all) do
      Fabricator(:person) do
        first_name "Paul"
        last_name { |person| "#{person.first_name}#{person.age}" }
        age 60
      end
    end

    let(:person) { Fabricate(:person) }

    it 'evaluates the fields in order of declaration' do
      person.last_name.should == "Paul"
    end

  end

  context 'multiple instance' do

    let(:person1) { Fabricate(:person, :first_name => 'Jane') }
    let(:person2) { Fabricate(:person, :first_name => 'John') }

    before(:all) do
      Fabricator(:person) do
        first_name { Faker::Name.first_name }
        last_name { Faker::Name.last_name }
        age { rand(100) }
      end
    end

    it 'person1 is named Jane' do
      person1.first_name.should == 'Jane'
    end

    it 'person2 is named John' do
      person2.first_name.should == 'John'
    end

    it 'they have different last names' do
      person1.last_name.should_not == person2.last_name
    end

  end

  context 'with a specified class name' do

    let(:someone) { Fabricate(:someone) }

    before do
      Fabricator(:someone, :class_name => :person) do
        first_name "Paul"
      end
    end

    it 'generates the person as someone' do
      someone.first_name.should == "Paul"
    end

  end

 context 'stubbing methods' do
   before(:all) do 
     Fabricator(:company) do 
       unknown_attribute(:force => true){"Awesome value"}
       another_unknown "Another Awesome Val"
       unknown_block(:force => true){Fabricate(:division)}
     end 

     Fabricator(:division) do
       name "Awesome division"
     end      
   end

   before { TestMigration.up }
   after { TestMigration.down }

   let(:company) { Fabricate(:company) }
   
   it "stubs methods when args in attr" do 
     company.unknown_attribute.should == "Awesome value"
   end

   it "stubs methods with value" do 
     company.another_unknown.should == "Another Awesome Val"
   end

   it "stubs methods with block" do
     company.unknown_block.name.should == "Awesome division"
   end
 end

  context 'with an active record object' do

    before(:all) do
      Fabricator(:company) do
        name { Faker::Company.name }
        divisions!(:count => 4) { Fabricate(:division) }
        after_create { |o| o.update_attribute(:city, "Jacksonville Beach") }
      end

      Fabricator(:other_company, :from => :company) do
        divisions(:count => 2) { Fabricate(:division) }
      end

      Fabricator(:division) do
        name "Awesome Division"
      end
    end

    before { TestMigration.up }
    after { TestMigration.down }

    let(:company) { Fabricate(:company, :name => "Hashrocket") }

    it 'generates field blocks immediately' do
      company.name.should == "Hashrocket"
    end

    it 'generates associations immediately when forced' do
      Division.find_all_by_company_id(company.id).count.should == 4
    end

    it 'executes after create blocks' do
      company.city.should == 'Jacksonville Beach'
    end

    it 'overrides associations' do
      Fabricate(:company, :divisions => []).divisions.should == []
    end

    it 'overrides inherited associations' do
      Fabricate(:other_company).divisions.count.should == 2
      Division.count.should == 2
    end

  end

  context 'with a mongoid document' do

    before(:all) do
      Fabricator(:author) do
        name "George Orwell"
        books(:count => 4) do |author, i|
          Fabricate(:book, :title => "book title #{i}", :author => author)
        end
      end

      Fabricator(:book) do
        title "1984"
      end
    end

    let(:author) { Fabricate(:author) }

    it "sets the author name" do
      author.name.should == "George Orwell"
    end

    it 'generates four books' do
      author.books.map(&:title).should == (1..4).map { |i| "book title #{i}" }
    end
  end

  context 'with a parent fabricator' do

    context 'and a previously defined parent' do

      let(:ernie) { Fabricate(:hemingway) }

      before(:all) do
        Fabricator(:book)
        Fabricator(:author) do
          name 'George Orwell'
          books { |author| [Fabricate(:book, :title => '1984', :author => author)] }
        end

        Fabricator(:hemingway, :from => :author) do
          name 'Ernest Hemingway'
        end
      end

      it 'has the values from the parent' do
        ernie.books.map(&:title).should == ['1984']
      end

      it 'overrides specified values from the parent' do
        ernie.name.should == 'Ernest Hemingway'
      end

    end

    context 'and a class name as a parent' do

      before(:all) do
        Fabricator(:hemingway, :from => :author) do
          name 'Ernest Hemingway'
        end
      end

      let(:ernie) { Fabricate(:hemingway) }

      it 'has the name defined' do
        ernie.name.should == 'Ernest Hemingway'
      end

      it 'not have any books' do
        ernie.books.should == []
      end

    end

  end

  describe '.clear_definitions' do

    before(:all) do
      Fabricator(:author) {}
      Fabrication.clear_definitions
    end

    it 'should not generate authors' do
      Fabrication.fabricators.has_key?(:author).should be_false
    end

  end

  context 'when defining a fabricator twice' do

    before(:all) do
      Fabricator(:author) {}
    end

    it 'throws an error' do
      lambda { Fabricator(:author) {} }.should raise_error(Fabrication::DuplicateFabricatorError)
    end

  end

  context 'when generating from a non-existant fabricator' do

    it 'throws an error' do
      lambda { Fabricate(:your_mom) }.should raise_error(Fabrication::UnknownFabricatorError)
    end

  end

  context 'defining a fabricator without a block' do

    before(:all) { Fabricator(:author) }

    it 'works fine' do
      Fabricate(:author).should be
    end

  end

  describe ".fabricators" do

    let(:author) { Fabricator(:author) }
    let(:book) { Fabricator(:book) }

    before(:all) { author; book }

    it "returns the two fabricators" do
      Fabrication.fabricators.should == {:author => author, :book => book}
    end

  end

  describe "Fabricate with a block" do

    let(:person) do
      Fabricate(:person) do
        first_name "Paul"
        last_name { "Elliott" }
      end
    end

    it 'uses the class matching the passed-in symbol' do
      person.kind_of?(Person).should be_true
    end

    it 'has the correct first_name' do
      person.first_name.should == 'Paul'
    end

    it 'has the correct last_name' do
      person.last_name.should == 'Elliott'
    end

    it 'has the correct age' do
      person.age.should be_nil
    end

  end

  describe "Fabricate.attributes_for" do

    before(:all) do
      Fabricator(:person) do
        first_name "Paul"
        last_name { "Elliott" }
      end
    end

    let(:person) { Fabricate.attributes_for(:person) }

    it 'has the first name as a parameter' do
      person['first_name'].should == "Paul"
    end

    it 'has the last name as a parameter' do
      person[:last_name].should == "Elliott"
    end

  end

end
