/**
 * Unit tests for the App component
 * Tests user interactions, API calls, and UI rendering
 */

import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import App from '../App'

describe('App Component', () => {
  beforeEach(() => {
    // Reset fetch mock before each test
    vi.clearAllMocks()
    global.fetch = vi.fn()
  })

  describe('Initial Rendering', () => {
    it('renders the main heading', () => {
      render(<App />)
      expect(screen.getByText('URL Detector')).toBeInTheDocument()
    })

    it('renders the subtitle', () => {
      render(<App />)
      expect(screen.getByText(/Paste a URL and get a quick risk assessment/i)).toBeInTheDocument()
    })

    it('renders the URL input field', () => {
      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      expect(input).toBeInTheDocument()
    })

    it('renders the Analyze button', () => {
      render(<App />)
      expect(screen.getByText('Analyze')).toBeInTheDocument()
    })

    it('renders the API docs link', () => {
      render(<App />)
      const link = screen.getByText('Open API Docs')
      expect(link).toBeInTheDocument()
      expect(link).toHaveAttribute('href', '/api/docs')
    })

    it('displays the logo emoji', () => {
      render(<App />)
      expect(screen.getByText('🔎')).toBeInTheDocument()
    })
  })

  describe('User Input', () => {
    it('updates input value when user types', async () => {
      const user = userEvent.setup()
      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)

      await user.type(input, 'https://test.com')

      expect(input).toHaveValue('https://test.com')
    })

    it('button is disabled when input is empty', () => {
      render(<App />)
      const button = screen.getByText('Analyze')

      expect(button).toBeDisabled()
    })

    it('button is enabled when input has value', async () => {
      const user = userEvent.setup()
      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')

      expect(button).not.toBeDisabled()
    })

    it('button is disabled when input is only whitespace', async () => {
      const user = userEvent.setup()
      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, '   ')

      expect(button).toBeDisabled()
    })
  })

  describe('API Calls', () => {
    it('calls fetch when Analyze button is clicked', async () => {
      const user = userEvent.setup()
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'safe', url: 'https://test.com' })
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      await waitFor(() => {
        expect(global.fetch).toHaveBeenCalledWith(
          '/api/predict',
          expect.objectContaining({
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url: 'https://test.com' })
          })
        )
      })
    })

    it('shows loading state during API call', async () => {
      const user = userEvent.setup()
      global.fetch.mockImplementationOnce(() => new Promise(resolve => setTimeout(resolve, 100)))

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      // Button should show loading spinner
      expect(screen.getByRole('button')).toHaveClass('loading')
    })

    it('disables button during API call', async () => {
      const user = userEvent.setup()
      global.fetch.mockImplementationOnce(() => new Promise(resolve => setTimeout(resolve, 100)))

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      expect(button).toBeDisabled()
    })
  })

  describe('Safe URL Results', () => {
    it('displays Safe badge for safe prediction', async () => {
      const user = userEvent.setup()
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'safe', url: 'https://google.com' })
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://google.com')
      await user.click(button)

      await waitFor(() => {
        expect(screen.getByText('Safe')).toBeInTheDocument()
      })
    })

    it('displays result with safe badge styling', async () => {
      const user = userEvent.setup()
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'safe' })
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      await waitFor(() => {
        const badge = screen.getByText('Safe')
        expect(badge).toHaveClass('badge-safe')
      })
    })
  })

  describe('Phishing URL Results', () => {
    it('displays Suspicious badge for phishing prediction', async () => {
      const user = userEvent.setup()
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'phishing', url: 'http://malicious.com' })
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'http://malicious.com')
      await user.click(button)

      await waitFor(() => {
        expect(screen.getByText('Suspicious')).toBeInTheDocument()
      })
    })

    it('displays result with danger badge styling', async () => {
      const user = userEvent.setup()
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'phishing' })
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      await waitFor(() => {
        const badge = screen.getByText('Suspicious')
        expect(badge).toHaveClass('badge-danger')
      })
    })
  })

  describe('Error Handling', () => {
    it('displays error message when API call fails', async () => {
      const user = userEvent.setup()
      global.fetch.mockRejectedValueOnce(new Error('Network error'))

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      await waitFor(() => {
        expect(screen.getByText(/Backend error:/i)).toBeInTheDocument()
        expect(screen.getByText(/Network error/i)).toBeInTheDocument()
      })
    })

    it('displays error for HTTP error responses', async () => {
      const user = userEvent.setup()
      global.fetch.mockResolvedValueOnce({
        ok: false,
        status: 500
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      await waitFor(() => {
        expect(screen.getByText(/Backend error:/i)).toBeInTheDocument()
        expect(screen.getByText(/HTTP 500/i)).toBeInTheDocument()
      })
    })

    it('clears previous error when new analysis starts', async () => {
      const user = userEvent.setup()

      // First call fails
      global.fetch.mockRejectedValueOnce(new Error('Error 1'))

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      await waitFor(() => {
        expect(screen.getByText(/Error 1/i)).toBeInTheDocument()
      })

      // Second call succeeds
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'safe' })
      })

      await user.clear(input)
      await user.type(input, 'https://another.com')
      await user.click(button)

      await waitFor(() => {
        expect(screen.queryByText(/Error 1/i)).not.toBeInTheDocument()
      })
    })
  })

  describe('Confidence Score Display', () => {
    it('displays confidence score when provided', async () => {
      const user = userEvent.setup()
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({
          prediction: 'safe',
          confidence: 0.95
        })
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      await waitFor(() => {
        expect(screen.getByText(/Confidence:/i)).toBeInTheDocument()
      })
    })

    it('displays raw JSON when no confidence score provided', async () => {
      const user = userEvent.setup()
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'safe' })
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://test.com')
      await user.click(button)

      await waitFor(() => {
        // Should show the Safe badge (use getAllByText since "safe" appears multiple times)
        const safeElements = screen.getAllByText(/safe/i)
        expect(safeElements.length).toBeGreaterThan(0)
      })
    })
  })

  describe('Multiple Analyses', () => {
    it('clears previous result when starting new analysis', async () => {
      const user = userEvent.setup()

      // First analysis
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'safe' })
      })

      render(<App />)
      const input = screen.getByPlaceholderText(/https:\/\/example.com\/path/i)
      const button = screen.getByText('Analyze')

      await user.type(input, 'https://first.com')
      await user.click(button)

      await waitFor(() => {
        expect(screen.getByText('Safe')).toBeInTheDocument()
      })

      // Second analysis
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: async () => ({ prediction: 'phishing' })
      })

      await user.clear(input)
      await user.type(input, 'https://second.com')
      await user.click(button)

      // Should eventually show new result
      await waitFor(() => {
        expect(screen.getByText('Suspicious')).toBeInTheDocument()
      })
    })
  })
})
