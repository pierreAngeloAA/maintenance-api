require "rails_helper"

RSpec.describe Session, type: :model do
  let(:user) { create(:user) }

  it "genera un token al crearse" do
    session = user.sessions.create!

    expect(session.token).to be_present
    expect(session.token.length).to be > 20
  end

  it "guarda el digest del token, nunca el token" do
    session = user.sessions.create!

    expect(session.token_digest).to be_present
    expect(session.token_digest).not_to eq(session.token)
  end

  it "el token solo esta disponible en el objeto recien creado" do
    session = user.sessions.create!

    expect(Session.find(session.id).token).to be_nil
  end

  it "encuentra la sesion a partir del token" do
    session = user.sessions.create!

    expect(described_class.authenticate(session.token)).to eq(session)
  end

  it "no encuentra nada con un token que no existe" do
    expect(described_class.authenticate("token-inventado")).to be_nil
  end

  it "no revienta con un token vacio" do
    expect(described_class.authenticate(nil)).to be_nil
    expect(described_class.authenticate("")).to be_nil
  end
end
