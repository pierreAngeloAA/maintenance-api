require "rails_helper"

RSpec.describe User, type: :model do
  describe "validaciones" do
    it "es valido con los atributos de la factory" do
      expect(build(:user)).to be_valid
    end

    it "exige correo" do
      expect(build(:user, email: nil)).not_to be_valid
    end

    it "rechaza un correo con formato invalido" do
      expect(build(:user, email: "esto-no-es-un-correo")).not_to be_valid
    end

    it "normaliza el correo a minusculas y sin espacios" do
      user = create(:user, email: "  Pierre@Example.COM ")

      expect(user.email).to eq("pierre@example.com")
    end

    it "no permite dos usuarios con el mismo correo, ni cambiando mayusculas" do
      create(:user, email: "pierre@example.com")

      expect(build(:user, email: "PIERRE@example.com")).not_to be_valid
    end

    it "exige una contrasena de al menos 8 caracteres" do
      expect(build(:user, password: "corta1")).not_to be_valid
      expect(build(:user, password: "suficiente1")).to be_valid
    end
  end

  describe "contrasena" do
    it "nunca guarda la contrasena en claro" do
      user = create(:user, password: "unaClaveSegura1")

      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to include("unaClaveSegura1")
    end

    it "autentica con la contrasena correcta" do
      user = create(:user, password: "unaClaveSegura1")

      expect(user.authenticate("unaClaveSegura1")).to eq(user)
    end

    it "no autentica con la contrasena equivocada" do
      user = create(:user, password: "unaClaveSegura1")

      expect(user.authenticate("otraCosa")).to be(false)
    end
  end

  describe "asociaciones" do
    it "borra sus vehiculos y sesiones al borrarse" do
      user = create(:user)
      create(:vehicle, user: user)
      user.sessions.create!

      expect { user.destroy }.to change(Garage::Vehicle, :count).by(-1).and change(Session, :count).by(-1)
    end
  end
end
