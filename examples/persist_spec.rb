def persist model
  return model if model.save
end

context 'when testing generic object interaction' do
  describe '#persist' do
    let(:model) { double :model, save: persistence_result }
    let(:persistence_result) { true }

    it 'calls "save" on the model' do
      expect(model).to receive(:save)
      persist model
    end

    context 'when the model persists successfully' do
      let(:persistence_result) { true }

      it 'returns the persisted model' do
        expect(persist model).to eq model
      end
    end

    context 'when the model fails to persist' do
      let(:persistence_result) { false }

      it 'returns nil' do
        expect(persist model).to be_nil
      end
    end
  end
end

def persist_user user
  return user if user.save
end

class User
  def save
  end
end

context 'when testing specific object interaction' do
  describe '#persist_user' do
    let(:user) { object_double User.new, save: persistence_result }
    let(:persistence_result) { true }

    it 'calls "save" on the user' do
      expect(user).to receive(:save)
      persist_user user
    end

    context 'when the user persists successfully' do
      let(:persistence_result) { true }

      it 'returns the persisted user' do
        expect(persist_user user).to eq user
      end
    end

    context 'when the user fails to persist' do
      let(:persistence_result) { false }

      it 'returns nil' do
        expect(persist_user user).to be_nil
      end
    end
  end
end
