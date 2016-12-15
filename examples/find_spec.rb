class User
  def self.find id
  end
end

def injectable_find_or_create id, repository=User
  repository.find(id) || repository.new
end

context 'when using injection' do
  describe '#find_or_create' do
    let(:repository) { class_double 'User', find: repository_result, new: :new_record }

    context 'when the record is found' do
      let(:repository_result) { :existing_record }

      it 'returns the existing record' do
        expect(injectable_find_or_create 123, repository).to eq :existing_record
      end
    end

    context 'when the record is not found' do
      let(:repository_result) { nil }

      it 'uses repository to create a new user' do
        expect(repository).to receive :new
        injectable_find_or_create 123, repository
      end

      it 'returns a new record' do
        expect(injectable_find_or_create 123, repository).to eq :new_record
      end
    end
  end
end

def find_or_create id
  User.find(id) || User.new
end

context 'when stubbing constants' do
  describe '#find_or_create' do
    before { class_double('User', find: repository_result, new: :new_record).as_stubbed_const }

    context 'when the record is found' do
      let(:repository_result) { :existing_record }

      it 'returns the existing record' do
        expect(find_or_create 123).to eq :existing_record
      end
    end

    context 'when the record is not found' do
      let(:repository_result) { nil }

      it 'uses User to create a new user' do
        expect(User).to receive :new
        find_or_create 123
      end

      it 'returns a new record' do
        expect(find_or_create 123).to eq :new_record
      end
    end
  end
end
